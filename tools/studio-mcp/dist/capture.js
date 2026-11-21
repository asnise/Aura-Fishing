// src/capture.ts
import { execFile } from "child_process";
import { existsSync, readFileSync } from "fs";
import { dirname, join, resolve } from "path";
import { fileURLToPath } from "url";
var here = dirname(fileURLToPath(import.meta.url));
function scriptPath() {
  const p = [join(here, "..", "scripts", "capture-window.ps1"), join(here, "capture-window.ps1")].find(existsSync);
  if (!p) throw new Error("capture-window.ps1 not found next to the bridge");
  return p;
}
function ps(args) {
  return new Promise((res, rej) => {
    execFile(
      "powershell.exe",
      ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", scriptPath(), ...args],
      { windowsHide: true, timeout: 6e4, maxBuffer: 4 * 1024 * 1024 },
      (err, stdout, stderr) => {
        const line = stdout.trim().split(/\r?\n/).filter((l) => l.startsWith("{")).pop();
        if (line) {
          try {
            return res(JSON.parse(line));
          } catch {
          }
        }
        const msg = (stderr || String(err || "")).split(/\r?\n/).find((l) => /\S/.test(l) && !l.startsWith("At ") && !l.trim().startsWith("+")) || "capture failed";
        rej(new Error(msg.replace(/^.*?:\s*/, "").trim() || msg));
      }
    );
  });
}
var sleep = (ms) => new Promise((r) => setTimeout(r, ms));
var lit = (src) => "[==[" + src + "]==]";
function legacySend(send) {
  let loaded = false;
  return async (command, params, timeoutMs) => {
    if (!loaded) {
      const dir = [join(here, "..", "plugin", "src")].find((d) => existsSync(join(d, "Capture.luau")));
      if (!dir) throw new Error("plugin has no capture commands and plugin/src was not found; reinstall the plugin and restart Studio");
      const code = [
        'local f = Instance.new("Folder")',
        `local p = Instance.new("ModuleScript") p.Name = "Path" p.Source = ${lit(readFileSync(join(dir, "Path.luau"), "utf8"))} p.Parent = f`,
        `local c = Instance.new("ModuleScript") c.Name = "Capture" c.Source = ${lit(readFileSync(join(dir, "Capture.luau"), "utf8"))} c.Parent = f`,
        "_G.__StudioBridgeCapture = require(c)",
        "return true"
      ].join("\n");
      const r2 = await send("run_luau", { code }, 2e4);
      if (r2.error) throw new Error("loading capture code failed: " + r2.error);
      loaded = true;
    }
    const r = await send(
      "run_luau",
      { code: `return _G.__StudioBridgeCapture.${command}(game:GetService("HttpService"):JSONDecode(${lit(JSON.stringify(params))}))` },
      timeoutMs
    );
    if (r.error) throw new Error(r.error.split(String.fromCharCode(10))[0].trim());
    return r.returns[0];
  };
}
async function captureUi(send, o) {
  if (process.platform !== "win32") throw new Error("capture_ui only works on Windows");
  const out = resolve(o.out);
  const prepParams = { path: o.path, isolate: o.isolate, background: o.background };
  let prep;
  try {
    prep = await send("capture_prepare", prepParams, 2e4);
  } catch (e) {
    if (!/unknown command/.test(e.message)) throw e;
    send = legacySend(send);
    prep = await send("capture_prepare", prepParams, 2e4);
  }
  try {
    await sleep(150);
    const found = await ps(["-Mode", "find", "-Title", prep.place, "-Method", o.method || "auto"]).catch((e) => {
      throw new Error(`${e.message} (Stop Play mode; the plugin draws in the Edit viewport.)`);
    });
    const m = found.marker;
    const scaleX = m.w / prep.markerSize;
    const scaleY = m.h / prep.markerSize;
    const scale = Math.round((scaleX + scaleY) / 2 * 1e3) / 1e3;
    const pad = o.padding ?? 0;
    const x = Math.round(m.x + (prep.target.x - prep.marker.x - pad) * scaleX);
    const y = Math.round(m.y + (prep.target.y - prep.marker.y - pad) * scaleY);
    const w = Math.round((prep.target.w + pad * 2) * scaleX);
    const h = Math.round((prep.target.h + pad * 2) * scaleY);
    await send("capture_marker", { token: prep.token, visible: false }, 1e4);
    await sleep(150);
    const crop = await ps(["-Mode", "crop", "-Hwnd", String(found.hwnd), "-Method", found.method, "-X", String(x), "-Y", String(y), "-W", String(w), "-H", String(h), "-Out", out]);
    return {
      out: crop.out,
      size: { w: crop.w, h: crop.h },
      clipped: crop.clipped,
      scale,
      guiRect: prep.target,
      viewport: prep.viewport,
      viewportPx: { w: Math.round(prep.viewport.w * scaleX), h: Math.round(prep.viewport.h * scaleY) },
      method: found.method,
      window: found.title,
      note: scale !== 1 ? `Studio draws 1 GUI unit as ${scale} screen px (Windows display scaling). Divide by ${scale} to compare with 1x Figma exports.` : void 0
    };
  } finally {
    await send("capture_restore", { token: prep.token }, 1e4).catch(() => {
    });
  }
}
export {
  captureUi
};
//# sourceMappingURL=capture.js.map