import { describe, test, expect, afterEach } from "bun:test";
import { Bridge, BridgeClient, BridgeError, clampTimeout } from "../src/bridge";

const H = { "x-studio-bridge": "1", "Content-Type": "application/json" };
let port = 3900 + Math.floor(Math.random() * 500);
const open: Bridge[] = [];
afterEach(async () => {
  await Promise.all(open.splice(0).map((b) => b.close()));
});

async function started(opts = {}) {
  const b = new Bridge({ pollHoldMs: 300, ...opts });
  open.push(b);
  const p = ++port;
  expect(await b.listen(p)).toBe(true);
  return { b, url: `http://127.0.0.1:${p}`, port: p };
}

describe("queue", () => {
  test("send -> poll -> complete resolves", async () => {
    const b = new Bridge({ pollHoldMs: 200 });
    const res = b.send("get_tree", { path: "Workspace" }, 2000);
    const cmds = await b.poll("c1");
    expect(cmds).toHaveLength(1);
    expect(cmds[0].command).toBe("get_tree");
    expect(cmds[0].params).toEqual({ path: "Workspace" });
    expect(cmds[0].timeoutMs).toBe(2000);
    expect(b.complete(cmds[0].id, true, { ok: 1 })).toBe(true);
    expect(await res).toEqual({ ok: 1 });
    expect(b.pending.size).toBe(0);
  });

  test("a waiting poll is woken by a new command", async () => {
    const b = new Bridge({ pollHoldMs: 5000 });
    const polled = b.poll("c1");
    await Bun.sleep(20);
    const res = b.send("noop", {}, 2000);
    const cmds = await polled;
    expect(cmds.map((c) => c.command)).toEqual(["noop"]);
    b.complete(cmds[0].id, true, "pong");
    expect(await res).toBe("pong");
  });

  test("empty poll returns [] after hold time", async () => {
    const b = new Bridge({ pollHoldMs: 50 });
    const t = Date.now();
    expect(await b.poll("c1")).toEqual([]);
    expect(Date.now() - t).toBeGreaterThanOrEqual(40);
  });

  test("error result rejects with message", async () => {
    const b = new Bridge();
    const res = b.send("delete_instance", {}, 2000);
    const [cmd] = await b.poll("c1", {}, 0);
    b.complete(cmd.id, false, undefined, "path not found");
    await expect(res).rejects.toThrow("path not found");
  });

  test("timeout without client explains that no plugin is connected and drops the command", async () => {
    const b = new Bridge();
    await expect(b.send("noop", {}, 50)).rejects.toThrow(/No Studio plugin connected/);
    expect(b.queue).toHaveLength(0);
    expect(b.pending.size).toBe(0);
  });

  test("timeout after delivery says Studio did not answer; late result is ignored", async () => {
    const b = new Bridge();
    const res = b.send("run_luau", {}, 50);
    const [cmd] = await b.poll("c1", {}, 0);
    await expect(res).rejects.toThrow(/did not answer/);
    expect(b.complete(cmd.id, true, 1)).toBe(false);
  });

  test("commands are delivered once, in order", async () => {
    const b = new Bridge();
    const ps = ["a", "b", "c"].map((c) => b.send(c, {}, 2000));
    const cmds = await b.poll("c1", {}, 0);
    expect(cmds.map((c) => c.command)).toEqual(["a", "b", "c"]);
    expect(await b.poll("c2", {}, 0)).toEqual([]);
    cmds.forEach((c, i) => b.complete(c.id, true, i));
    expect(await Promise.all(ps)).toEqual([0, 1, 2]);
  });

  test("clients are tracked with place info and go stale", async () => {
    const b = new Bridge({ clientStaleMs: 30 });
    await b.poll("c1", { place: "AuraFishing", version: "0.1.0" }, 0);
    expect(b.connectedClients().map((c) => c.place)).toEqual(["AuraFishing"]);
    await Bun.sleep(50);
    expect(b.connectedClients()).toEqual([]);
  });

  test("cancelAll rejects pending", async () => {
    const b = new Bridge();
    const res = b.send("x", {}, 5000);
    b.cancelAll("bye");
    await expect(res).rejects.toThrow("bye");
  });

  test("clampTimeout", () => {
    expect(clampTimeout(undefined)).toBe(30000);
    expect(clampTimeout(10)).toBe(1000);
    expect(clampTimeout(1e9)).toBe(280000);
  });
});

describe("http", () => {
  test("rejects requests without the bridge header or with an Origin", async () => {
    const { url } = await started();
    expect((await fetch(`${url}/status`)).status).toBe(403);
    expect((await fetch(`${url}/status`, { headers: { ...H, Origin: "https://evil.example" } })).status).toBe(403);
    expect((await fetch(`${url}/status`, { headers: H })).status).toBe(200);
  });

  test("full round trip: /command -> /poll -> /result", async () => {
    const { url } = await started({ pollHoldMs: 2000 });
    const cmdP = fetch(`${url}/command`, {
      method: "POST",
      headers: H,
      body: JSON.stringify({ command: "get_selection", params: { a: 1 }, timeoutMs: 3000 }),
    }).then((r) => r.json());
    const poll = (await (await fetch(`${url}/poll?client=p1&place=Test&wait=2000`, { headers: H })).json()) as any;
    expect(poll.commands).toHaveLength(1);
    const c = poll.commands[0];
    expect(c.command).toBe("get_selection");
    const r = await (
      await fetch(`${url}/result`, { method: "POST", headers: H, body: JSON.stringify({ id: c.id, ok: true, result: ["Workspace.Part"] }) })
    ).json();
    expect(r).toEqual({ ok: true, known: true });
    expect(await cmdP).toEqual({ ok: true, result: ["Workspace.Part"] });
    const st = (await (await fetch(`${url}/status`, { headers: H })).json()) as any;
    expect(st.clients[0].place).toBe("Test");
  });

  test("/command reports Studio errors as ok:false", async () => {
    const { b, url } = await started();
    const cmdP = fetch(`${url}/command`, { method: "POST", headers: H, body: JSON.stringify({ command: "x", timeoutMs: 3000 }) }).then((r) =>
      r.json(),
    );
    await Bun.sleep(30);
    const [c] = await b.poll("p", {}, 0);
    b.complete(c.id, false, undefined, "boom");
    expect(await cmdP).toEqual({ ok: false, error: "boom" });
  });

  test("static routes and 404", async () => {
    const b = new Bridge({ staticRoutes: { "/classes": () => ({ Part: { super: "BasePart", props: [] } }) } });
    open.push(b);
    const p = ++port;
    await b.listen(p);
    expect(await (await fetch(`http://127.0.0.1:${p}/classes`, { headers: H })).json()).toEqual({ Part: { super: "BasePart", props: [] } });
    expect((await fetch(`http://127.0.0.1:${p}/nope`, { headers: H })).status).toBe(404);
  });

  test("bad JSON body gives 500 not a crash", async () => {
    const { url } = await started();
    const r = await fetch(`${url}/result`, { method: "POST", headers: H, body: "{not json" });
    expect(r.status).toBe(500);
    expect((await fetch(`${url}/status`, { headers: H })).status).toBe(200);
  });

  test("listen returns false when the port is taken", async () => {
    const { port: p } = await started();
    const b2 = new Bridge();
    expect(await b2.listen(p)).toBe(false);
  });
});

describe("BridgeClient", () => {
  test("second instance proxies through the owner", async () => {
    const owner = new Bridge({ pollHoldMs: 2000 });
    const proxyBridge = new Bridge();
    open.push(owner, proxyBridge);
    const p = ++port;
    const a = new BridgeClient(owner, p);
    const b = new BridgeClient(proxyBridge, p);
    await a.start();
    await b.start();
    expect(a.mode).toBe("owner");
    expect(b.mode).toBe("proxy");
    const res = b.send("get_tree", { depth: 1 }, 3000);
    const [c] = await owner.poll("plugin", {}, 2000);
    expect(c.command).toBe("get_tree");
    owner.complete(c.id, true, { name: "game" });
    expect(await res).toEqual({ name: "game" });
  });

  test("proxy takes over the port when the owner exits", async () => {
    const owner = new Bridge();
    const proxyBridge = new Bridge();
    open.push(proxyBridge);
    const p = ++port;
    const a = new BridgeClient(owner, p);
    const b = new BridgeClient(proxyBridge, p);
    await a.start();
    await b.start();
    await owner.close();
    const res = b.send("noop", {}, 2000);
    await Bun.sleep(30);
    expect(b.mode).toBe("owner");
    const [c] = await proxyBridge.poll("plugin", {}, 0);
    proxyBridge.complete(c.id, true, "pong");
    expect(await res).toBe("pong");
  });

  test("proxy surfaces remote errors as BridgeError", async () => {
    const owner = new Bridge();
    const proxyBridge = new Bridge();
    open.push(owner, proxyBridge);
    const p = ++port;
    await new BridgeClient(owner, p).start();
    const b = new BridgeClient(proxyBridge, p);
    await b.start();
    await expect(b.send("noop", {}, 1000)).rejects.toBeInstanceOf(BridgeError);
  });
});
