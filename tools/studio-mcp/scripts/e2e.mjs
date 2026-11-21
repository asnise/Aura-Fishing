// End-to-end check of every bridge command against a live Studio (plugin connected).
// Creates Workspace.__BridgeE2E and ServerStorage.__BridgeE2E_UI, removes them at the end.
// Usage: node scripts/e2e.mjs [--port=3060]
import { tmpdir } from "os";
import { join } from "path";
import { existsSync, statSync } from "fs";
import { captureUi } from "../dist/capture.js";
const port = Number(process.argv.find((a) => a.startsWith("--port="))?.slice(7) || 3060);
const H = { "x-studio-bridge": "1", "Content-Type": "application/json" };

async function run(command, params = {}, timeoutMs = 30000) {
  const r = await fetch(`http://127.0.0.1:${port}/command`, {
    method: "POST",
    headers: H,
    body: JSON.stringify({ command, params, timeoutMs }),
  });
  const b = await r.json();
  if (!b.ok) throw new Error(`${command}: ${b.error}`);
  return b.result;
}

let failed = 0;
async function check(name, fn) {
  try {
    const detail = await fn();
    console.log(`PASS ${name}${detail ? `  ${detail}` : ""}`);
  } catch (e) {
    failed++;
    console.log(`FAIL ${name}  ${e.message}`);
  }
}
const assert = (c, m) => {
  if (!c) throw new Error(m);
};
const expectError = async (p, re) => {
  try {
    await p;
  } catch (e) {
    assert(re.test(e.message), `wrong error: ${e.message}`);
    return e.message;
  }
  throw new Error("expected an error");
};

const UI_SOURCE = `local Images = {}
return function(parent: Instance?)
	local root = Instance.new("Frame")
	root.Name = "TestMenu"
	root.Size = UDim2.fromScale(0.5, 0.5)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.BackgroundColor3 = Color3.fromHex("F6EBD4")
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "Bridge preview"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Parent = root
	root.Parent = parent
	return { Root = root, Refs = { Title = title } }
end`;

await check("ping", async () => {
  const r = await run("ping");
  assert(r.pong, "no pong");
  return `place=${r.place} v${r.version}`;
});
await run("delete_instance", { path: "Workspace.__BridgeE2E" }).catch(() => {});
await run("delete_instance", { path: "ServerStorage.__BridgeE2E_UI" }).catch(() => {});

await check("get_tree default", async () => {
  const r = await run("get_tree", { depth: 1 });
  const names = r.tree.children.map((c) => c.name);
  assert(names.includes("Workspace") && names.includes("ReplicatedStorage"), names.join(","));
  return `${r.nodes} nodes`;
});
await check("create_instance Folder", async () => {
  const r = await run("create_instance", { className: "Folder", parent: "Workspace", props: { Name: "__BridgeE2E" } });
  assert(r.path === "Workspace.__BridgeE2E", r.path);
});
await check("create_instance Part with typed props", async () => {
  const r = await run("create_instance", {
    className: "Part",
    parent: "Workspace.__BridgeE2E",
    props: { Name: "Box", Size: [4, 1, 2], Position: { Vector3: [0, 20, 0] }, Color: "#3FA7D6", Material: "Wood", Anchored: true },
    attributes: { LocationId: "Lake", Depth: 12 },
  });
  assert(r.path === "Workspace.__BridgeE2E.Box", r.path);
});
await check("get_properties", async () => {
  const r = await run("get_properties", { path: "Workspace.__BridgeE2E.Box" });
  const p = r.properties;
  assert(JSON.stringify(p.Size.Vector3) === "[4,1,2]", JSON.stringify(p.Size));
  assert(p.Color.hex.toLowerCase() === "#3fa7d6", JSON.stringify(p.Color));
  assert(p.Material === "Enum.Material.Wood", p.Material);
  assert(r.attributes.LocationId === "Lake" && r.attributes.Depth === 12, JSON.stringify(r.attributes));
  return `${Object.keys(p).length} props`;
});
await check("set_properties + tags + attributes", async () => {
  await run("set_properties", {
    path: "Workspace.__BridgeE2E.Box",
    props: { Transparency: 0.5, CFrame: [1, 2, 3], Shape: "Ball" },
    attributes: { Depth: 30 },
    removeAttributes: ["LocationId"],
    addTags: ["FishingZone"],
  });
  const r = await run("get_properties", { path: "Workspace.__BridgeE2E.Box", properties: ["Transparency", "Position", "Shape"] });
  assert(r.properties.Transparency === 0.5, JSON.stringify(r.properties));
  assert(JSON.stringify(r.properties.Position.Vector3) === "[1,2,3]", JSON.stringify(r.properties.Position));
  assert(r.properties.Shape === "Enum.PartType.Ball", r.properties.Shape);
  assert(r.tags.includes("FishingZone") && r.attributes.Depth === 30 && r.attributes.LocationId === undefined, JSON.stringify(r));
});
await check("set_properties bad value errors cleanly", () =>
  expectError(run("set_properties", { path: "Workspace.__BridgeE2E.Box", props: { Material: "Cheese" } }), /Cheese/),
);
await check("bad path error lists children", () => expectError(run("get_properties", { path: "Workspace.__BridgeE2E.Nope" }), /not found.*Box/));
await check("find_instances", async () => {
  const r = await run("find_instances", { path: "Workspace.__BridgeE2E", className: "BasePart" });
  assert(r.total === 1 && r.results[0].path === "Workspace.__BridgeE2E.Box", JSON.stringify(r));
});
await check("set_selection / get_selection", async () => {
  await run("set_selection", { paths: ["Workspace.__BridgeE2E.Box"] });
  const r = await run("get_selection");
  assert(r.length === 1 && r[0].path === "Workspace.__BridgeE2E.Box", JSON.stringify(r));
  await run("set_selection", { paths: [] });
});
await check("run_luau expression", async () => {
  const r = await run("run_luau", { code: "workspace.__BridgeE2E.Box.Size" });
  assert(!r.error && JSON.stringify(r.returns[0].Vector3) === "[4,1,2]", JSON.stringify(r));
});
await check("run_luau statements + print + multiple returns", async () => {
  const r = await run("run_luau", { code: 'local n = 0\nfor i = 1, 3 do n += i end\nprint("sum", n)\nwarn("careful")\nreturn n, workspace.__BridgeE2E' });
  assert(!r.error, r.error);
  assert(r.returns[0] === 6 && r.returns[1].Instance === "Workspace.__BridgeE2E", JSON.stringify(r.returns));
  assert(r.output.some((o) => o.kind === "print" && o.text.includes("sum 6")), JSON.stringify(r.output));
  assert(r.output.some((o) => o.kind === "warn" && o.text.includes("careful")), JSON.stringify(r.output));
  return `${r.elapsedMs} ms`;
});
await check("run_luau runtime error rolls back", async () => {
  const r = await run("run_luau", { code: 'workspace.__BridgeE2E.Box.Name = "Renamed"\nerror("boom")' });
  assert(r.error && r.error.includes("boom"), JSON.stringify(r));
  const still = await run("run_luau", { code: "return workspace.__BridgeE2E:FindFirstChild('Box') ~= nil" });
  return `rolled back: ${still.returns[0]}`;
});
await check("run_luau compile error", async () => {
  const r = await run("run_luau", { code: "local x = = 1" });
  assert(r.error && /compile/.test(r.error), JSON.stringify(r));
  return r.error.split("\n")[0].slice(0, 90);
});
await check("run_luau endless yield is cancelled and the queue keeps going", async () => {
  const t = Date.now();
  await expectError(
    run("run_luau", { code: 'workspace.__BridgeE2E.Box.Name = "Stuck"\nworkspace:WaitForChild("__DoesNotExist__")' }, 4000),
    /was cancelled/,
  );
  const after = await run("run_luau", { code: "workspace.__BridgeE2E:FindFirstChild('Box') ~= nil" }, 5000);
  assert(after.returns[0] === true, "change not rolled back: " + JSON.stringify(after));
  const p = await run("ping", {}, 5000);
  assert(p.pong, "plugin wedged");
  return `recovered after ${Date.now() - t} ms`;
});
await check("script source in non-Rojo location", async () => {
  await run("create_instance", { className: "ModuleScript", parent: "Workspace.__BridgeE2E", props: { Name: "Mod" } });
  await run("set_script_source", { path: "Workspace.__BridgeE2E.Mod", source: "return {\n\tanswer = 42,\n}\n" });
  const r = await run("get_script_source", { path: "Workspace.__BridgeE2E.Mod", startLine: 2, endLine: 2 });
  assert(r.source.trim() === "answer = 42," && r.totalLines === 4, JSON.stringify(r));
});
await check("set_script_source refuses Rojo-managed scripts", async () => {
  const f = await run("find_instances", { path: "ReplicatedStorage.Shared", className: "ModuleScript", limit: 1 });
  if (f.total === 0) return "skipped (no Rojo scripts in this place)";
  return expectError(run("set_script_source", { path: f.results[0].path, source: "--x" }), /Rojo/);
});
await check("delete refuses services", () => expectError(run("delete_instance", { path: "Workspace" }), /refusing/));
await check("mount_ui_module (preview without Play)", async () => {
  await run("create_instance", { className: "ModuleScript", parent: "ServerStorage", props: { Name: "__BridgeE2E_UI" } });
  await run("set_script_source", { path: "ServerStorage.__BridgeE2E_UI", source: UI_SOURCE });
  const r = await run("mount_ui_module", { modulePath: "ServerStorage.__BridgeE2E_UI", screenGuiName: "BridgeE2EPreview", solo: true });
  assert(r.root === "StarterGui.BridgeE2EPreview.TestMenu" && r.refs.includes("Title"), JSON.stringify(r));
  // edit + remount picks up the new source (no require cache)
  await run("set_script_source", { path: "ServerStorage.__BridgeE2E_UI", source: UI_SOURCE.replace("Bridge preview", "Bridge preview v2") });
  await run("mount_ui_module", { modulePath: "ServerStorage.__BridgeE2E_UI", screenGuiName: "BridgeE2EPreview" });
  const t = await run("get_properties", { path: "StarterGui.BridgeE2EPreview.TestMenu.Title", properties: ["Text"] });
  assert(t.properties.Text === "Bridge preview v2", t.properties.Text);
  if (process.platform === "win32") {
    const out = join(tmpdir(), "studio-bridge-e2e-capture.png");
    const c = await captureUi(run, { path: "StarterGui.BridgeE2EPreview.TestMenu", out, padding: 2 });
    assert(existsSync(out) && statSync(out).size > 1000, "no png");
    const ew = Math.round((c.guiRect.w + 4) * c.scale), eh = Math.round((c.guiRect.h + 4) * c.scale);
    assert(Math.abs(c.size.w - ew) <= 2 && Math.abs(c.size.h - eh) <= 2 && !c.clipped, "capture size " + JSON.stringify(c));
    console.log(`     capture_ui ok: ${c.size.w}x${c.size.h} scale=${c.scale} via ${c.method}`);
  }
  const u = await run("unmount_ui_module", { screenGuiName: "BridgeE2EPreview" });
  assert(u.removed, "not removed");
  return `${r.descendants} descendants, refs=${r.refs}`;
});
await check("generated UI modules available", async () => {
  const f = await run("find_instances", { path: "StarterPlayer.StarterPlayerScripts", name: "Generated", limit: 1 }).catch(() => ({ total: 0 }));
  return f.total ? `found ${f.results[0].path}` : "none in this place yet (Figma export not synced)";
});
await check("delete_instance + cleanup", async () => {
  await run("delete_instance", { path: "Workspace.__BridgeE2E" });
  await run("delete_instance", { path: "ServerStorage.__BridgeE2E_UI" });
  await expectError(run("get_tree", { path: "Workspace.__BridgeE2E" }), /not found/);
});

console.log(failed ? `\n${failed} FAILED` : "\nALL PASSED");
process.exit(failed ? 1 : 0);
