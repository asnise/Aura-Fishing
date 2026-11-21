// capture_ui: screenshot a GUI object that is drawn in the Studio edit viewport (Windows only).
// 1. plugin capture_prepare: target visible (+ isolated), #FF00FF marker at the viewport origin, GUI rects
// 2. scripts/capture-window.ps1 -Mode find: grab the Studio window, locate the marker -> origin + DPI scale
// 3. plugin capture_marker(false), then -Mode crop: second grab without the marker, crop the target rect
// 4. plugin capture_restore (always)

import { execFile } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export type Send = (command: string, params: Record<string, unknown>, timeoutMs?: number) => Promise<unknown>;

export interface CaptureOptions {
  path: string | string[];
  out: string;
  padding?: number; // GUI units around the target
  isolate?: boolean; // hide siblings / other ScreenGuis (default true)
  background?: string; // "#RRGGBB" solid backdrop behind the ScreenGui
  method?: "auto" | "print" | "screen";
}

interface Prepared {
  token: string;
  place: string;
  markerSize: number;
  marker: { x: number; y: number };
  target: { x: number; y: number; w: number; h: number };
  viewport: { w: number; h: number };
}

const here = dirname(fileURLToPath(import.meta.url));
function scriptPath() {
  const p = [join(here, "..", "scripts", "capture-window.ps1"), join(here, "capture-window.ps1")].find(existsSync);
  if (!p) throw new Error("capture-window.ps1 not found next to the bridge");
  return p;
}

function ps(args: string[]): Promise<any> {
  return new Promise((res, rej) => {
    execFile(
      "powershell.exe",
      ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", scriptPath(), ...args],
      { windowsHide: true, timeout: 60_000, maxBuffer: 4 * 1024 * 1024 },
      (err, stdout, stderr) => {
        const line = stdout.trim().split(/\r?\n/).filter((l) => l.startsWith("{")).pop();
        if (line) {
          try {
            return res(JSON.parse(line));
          } catch {}
        }
        const msg = (stderr || String(err || "")).split(/\r?\n/).find((l) => /\S/.test(l) && !l.startsWith("At ") && !l.trim().startsWith("+")) || "capture failed";
        rej(new Error(msg.replace(/^.*?:\s*/, "").trim() || msg));
      },
    );
  });
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

// Older plugin builds (before v0.2.0, Studio not restarted yet) have no capture_* commands. In that case load
// plugin/src/{Path,Capture}.luau into the running plugin with run_luau and call them through _G.
const lit = (src: string) => "[==[" + src + "]==]";
function legacySend(send: Send): Send {
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
        "return true",
      ].join("\n");
      const r = (await send("run_luau", { code }, 20_000)) as { error?: string };
      if (r.error) throw new Error("loading capture code failed: " + r.error);
      loaded = true;
    }
    const r = (await send(
      "run_luau",
      { code: `return _G.__StudioBridgeCapture.${command}(game:GetService("HttpService"):JSONDecode(${lit(JSON.stringify(params))}))` },
      timeoutMs,
    )) as { error?: string; returns: unknown[] };
    if (r.error) throw new Error(r.error.split(String.fromCharCode(10))[0].trim());
    return r.returns[0];
  };
}

export async function captureUi(send: Send, o: CaptureOptions) {
  if (process.platform !== "win32") throw new Error("capture_ui only works on Windows");
  const out = resolve(o.out);
  const prepParams = { path: o.path, isolate: o.isolate, background: o.background };
  let prep: Prepared;
  try {
    prep = (await send("capture_prepare", prepParams, 20_000)) as Prepared;
  } catch (e) {
    if (!/unknown command/.test((e as Error).message)) throw e;
    send = legacySend(send);
    prep = (await send("capture_prepare", prepParams, 20_000)) as Prepared;
  }
  try {
    await sleep(150);
    const found = await ps(["-Mode", "find", "-Title", prep.place, "-Method", o.method || "auto"]).catch((e: Error) => {
      throw new Error(`${e.message} (Stop Play mode; the plugin draws in the Edit viewport.)`);
    });
    const m = found.marker;
    const scaleX = m.w / prep.markerSize;
    const scaleY = m.h / prep.markerSize;
    const scale = Math.round(((scaleX + scaleY) / 2) * 1000) / 1000;
    const pad = o.padding ?? 0;
    // window-bitmap pixels of the target: marker origin + (GUI offset from marker) * scale
    const x = Math.round(m.x + (prep.target.x - prep.marker.x - pad) * scaleX);
    const y = Math.round(m.y + (prep.target.y - prep.marker.y - pad) * scaleY);
    const w = Math.round((prep.target.w + pad * 2) * scaleX);
    const h = Math.round((prep.target.h + pad * 2) * scaleY);

    await send("capture_marker", { token: prep.token, visible: false }, 10_000);
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
      note:
        scale !== 1
          ? `Studio draws 1 GUI unit as ${scale} screen px (Windows display scaling). Divide by ${scale} to compare with 1x Figma exports.`
          : undefined,
    };
  } finally {
    await send("capture_restore", { token: prep.token }, 10_000).catch(() => {});
  }
}
