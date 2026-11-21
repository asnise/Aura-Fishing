// Command queue + localhost HTTP server shared by the MCP server and the Studio plugin.
//
// Studio plugins cannot listen on sockets, so the plugin long-polls:
//   GET  /poll?client=<id>&place=<name>&wait=<ms>  -> { commands: [{ id, command, params }] }
//   POST /result  { id, ok, result?, error? }       -> { ok: true }
// Other local tools (test client, a second MCP instance) send commands with:
//   POST /command { command, params, timeoutMs }    -> { ok, result? , error? }
//   GET  /status                                    -> { bridge, clients, queued, pending }
//
// Every request must carry the header "X-Studio-Bridge: 1" and no Origin header. Custom
// headers force a CORS preflight that we never answer, so web pages cannot drive Studio.

import http from "node:http";
import { randomUUID } from "node:crypto";

export const BRIDGE_HEADER = "x-studio-bridge";
export const BRIDGE_NAME = "aura-studio-bridge";

export interface Command {
  id: string;
  command: string;
  params: Record<string, unknown>;
  /** How long the caller waits; the plugin aborts the command a little before this. */
  timeoutMs: number;
}

export interface ClientInfo {
  id: string;
  place: string;
  version: string;
  lastSeen: number;
}

interface Pending {
  command: Command;
  resolve: (v: unknown) => void;
  reject: (e: Error) => void;
  timer: ReturnType<typeof setTimeout>;
  delivered: boolean;
}

interface Waiter {
  clientId: string;
  respond: (cmds: Command[]) => void;
  timer: ReturnType<typeof setTimeout>;
}

export class BridgeError extends Error {}

export interface BridgeOptions {
  /** Max time a poll is held open when the queue is empty. */
  pollHoldMs?: number;
  /** Clients not seen for this long are considered disconnected. */
  clientStaleMs?: number;
  /** Extra GET routes (e.g. /classes) returning a JSON-serialisable value. */
  staticRoutes?: Record<string, () => unknown>;
  log?: (msg: string) => void;
}

export class Bridge {
  readonly queue: Command[] = [];
  readonly pending = new Map<string, Pending>();
  readonly clients = new Map<string, ClientInfo>();
  private waiters: Waiter[] = [];
  private server?: http.Server;
  private opts: Required<Omit<BridgeOptions, "staticRoutes">> & { staticRoutes: Record<string, () => unknown> };

  constructor(opts: BridgeOptions = {}) {
    this.opts = {
      pollHoldMs: opts.pollHoldMs ?? 15_000,
      clientStaleMs: opts.clientStaleMs ?? 25_000,
      staticRoutes: opts.staticRoutes ?? {},
      log: opts.log ?? (() => {}),
    };
  }

  // ---------------------------------------------------------------- queue

  /** Queue a command for Studio and wait for its result. */
  send(command: string, params: Record<string, unknown> = {}, timeoutMs = 30_000): Promise<unknown> {
    const cmd: Command = { id: randomUUID(), command, params, timeoutMs };
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        const p = this.pending.get(cmd.id);
        if (!p) return;
        this.pending.delete(cmd.id);
        const i = this.queue.indexOf(cmd);
        if (i >= 0) this.queue.splice(i, 1);
        const why = p.delivered
          ? `Studio did not answer "${command}" within ${timeoutMs} ms (it may still be running).`
          : this.connectedClients().length === 0
            ? `No Studio plugin connected. Open Studio, enable the "Studio Bridge" plugin and press Connect.`
            : `Studio did not pick up "${command}" within ${timeoutMs} ms.`;
        reject(new BridgeError(why));
      }, timeoutMs);
      this.pending.set(cmd.id, { command: cmd, resolve, reject, timer, delivered: false });
      this.queue.push(cmd);
      this.flush();
    });
  }

  /** Called by the plugin (via /poll). Returns queued commands now, or after a wait. */
  poll(clientId: string, info: Partial<ClientInfo> = {}, waitMs = this.opts.pollHoldMs): Promise<Command[]> {
    this.touch(clientId, info);
    if (this.queue.length > 0 || waitMs <= 0) return Promise.resolve(this.take());
    return new Promise((resolve) => {
      const waiter: Waiter = {
        clientId,
        respond: (cmds) => {
          clearTimeout(waiter.timer);
          this.waiters = this.waiters.filter((w) => w !== waiter);
          this.touch(clientId);
          resolve(cmds);
        },
        timer: setTimeout(() => waiter.respond([]), Math.min(waitMs, this.opts.pollHoldMs)),
      };
      this.waiters.push(waiter);
    });
  }

  /** Called by the plugin (via /result). Returns false if the id is unknown (e.g. timed out). */
  complete(id: string, ok: boolean, result?: unknown, error?: string): boolean {
    const p = this.pending.get(id);
    if (!p) return false;
    clearTimeout(p.timer);
    this.pending.delete(id);
    if (ok) p.resolve(result);
    else p.reject(new BridgeError(error || "Studio reported an error"));
    return true;
  }

  connectedClients(): ClientInfo[] {
    const now = Date.now();
    const waiting = new Set(this.waiters.map((w) => w.clientId));
    return [...this.clients.values()].filter((c) => waiting.has(c.id) || now - c.lastSeen < this.opts.clientStaleMs);
  }

  status() {
    return {
      bridge: BRIDGE_NAME,
      clients: this.connectedClients(),
      queued: this.queue.length,
      pending: this.pending.size,
    };
  }

  /** Reject everything (used on shutdown). */
  cancelAll(reason = "Bridge shut down") {
    for (const [id, p] of this.pending) {
      clearTimeout(p.timer);
      p.reject(new BridgeError(reason));
      this.pending.delete(id);
    }
    this.queue.length = 0;
    for (const w of [...this.waiters]) w.respond([]);
  }

  private take(): Command[] {
    const cmds = this.queue.splice(0, this.queue.length);
    for (const c of cmds) {
      const p = this.pending.get(c.id);
      if (p) p.delivered = true;
    }
    return cmds;
  }

  private flush() {
    if (this.queue.length === 0) return;
    const w = this.waiters[0];
    if (w) w.respond(this.take());
  }

  private touch(clientId: string, info: Partial<ClientInfo> = {}) {
    const prev = this.clients.get(clientId);
    this.clients.set(clientId, {
      id: clientId,
      place: info.place ?? prev?.place ?? "?",
      version: info.version ?? prev?.version ?? "?",
      lastSeen: Date.now(),
    });
  }

  // ---------------------------------------------------------------- HTTP

  /** Start listening on 127.0.0.1:port. Resolves false if the port is already taken. */
  listen(port: number): Promise<boolean> {
    return new Promise((resolve, reject) => {
      const server = http.createServer((req, res) => this.handle(req, res));
      server.keepAliveTimeout = 5_000;
      server.requestTimeout = 0; // /command may legitimately wait minutes
      server.once("error", (e: NodeJS.ErrnoException) => {
        if (e.code === "EADDRINUSE") resolve(false);
        else reject(e);
      });
      server.listen(port, "127.0.0.1", () => {
        this.server = server;
        resolve(true);
      });
    });
  }

  get listening() {
    return !!this.server;
  }

  close(): Promise<void> {
    this.cancelAll();
    const s = this.server;
    this.server = undefined;
    return new Promise((r) => (s ? s.close(() => r()) : r()));
  }

  private async handle(req: http.IncomingMessage, res: http.ServerResponse) {
    const send = (code: number, body: unknown) => {
      const text = JSON.stringify(body);
      res.writeHead(code, { "Content-Type": "application/json", "Cache-Control": "no-store" });
      res.end(text);
    };
    try {
      if (req.headers.origin || req.headers[BRIDGE_HEADER] !== "1") {
        return send(403, { ok: false, error: `missing ${BRIDGE_HEADER} header or cross-origin request` });
      }
      const url = new URL(req.url || "/", "http://127.0.0.1");
      const route = `${req.method} ${url.pathname}`;

      if (route === "GET /poll") {
        const client = url.searchParams.get("client") || "anonymous";
        const wait = Number(url.searchParams.get("wait") ?? this.opts.pollHoldMs);
        let closed = false;
        req.on("close", () => (closed = true));
        const cmds = await this.poll(
          client,
          { place: url.searchParams.get("place") ?? undefined, version: url.searchParams.get("version") ?? undefined },
          Number.isFinite(wait) ? wait : this.opts.pollHoldMs,
        );
        if (closed && cmds.length > 0) {
          // Plugin gave up on this poll; put the commands back for the next one.
          for (const c of cmds) {
            const p = this.pending.get(c.id);
            if (p) { p.delivered = false; this.queue.unshift(c); }
          }
          return;
        }
        return send(200, { commands: cmds });
      }
      if (route === "POST /result") {
        const body = (await readJson(req)) as { id?: string; ok?: boolean; result?: unknown; error?: string };
        if (!body || typeof body.id !== "string") return send(400, { ok: false, error: "id required" });
        const known = this.complete(body.id, body.ok !== false, body.result, body.error);
        return send(200, { ok: true, known });
      }
      if (route === "POST /command") {
        const body = (await readJson(req)) as { command?: string; params?: Record<string, unknown>; timeoutMs?: number };
        if (!body || typeof body.command !== "string") return send(400, { ok: false, error: "command required" });
        try {
          const result = await this.send(body.command, body.params ?? {}, clampTimeout(body.timeoutMs));
          return send(200, { ok: true, result });
        } catch (e) {
          return send(200, { ok: false, error: (e as Error).message });
        }
      }
      if (route === "GET /status") return send(200, this.status());
      if (req.method === "GET" && this.opts.staticRoutes[url.pathname]) {
        return send(200, this.opts.staticRoutes[url.pathname]());
      }
      return send(404, { ok: false, error: `no route ${route}` });
    } catch (e) {
      this.opts.log(`http error: ${(e as Error).stack}`);
      if (!res.headersSent) send(500, { ok: false, error: (e as Error).message });
    }
  }
}

export function clampTimeout(ms: unknown, def = 30_000): number {
  const n = Number(ms);
  if (!Number.isFinite(n) || n <= 0) return def;
  return Math.min(Math.max(n, 1_000), 280_000);
}

function readJson(req: http.IncomingMessage, limit = 20 * 1024 * 1024): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let size = 0;
    req.on("data", (c: Buffer) => {
      size += c.length;
      if (size > limit) { reject(new Error("body too large")); req.destroy(); return; }
      chunks.push(c);
    });
    req.on("end", () => {
      try {
        const text = Buffer.concat(chunks).toString("utf8");
        resolve(text ? JSON.parse(text) : {});
      } catch (e) {
        reject(e);
      }
    });
    req.on("error", reject);
  });
}

/**
 * Sends commands either through an in-process Bridge (this process owns the port) or,
 * when another process already owns it, through POST /command on that process.
 * If the owner goes away, the next call tries to take the port over.
 */
export class BridgeClient {
  private owner = false;

  constructor(readonly bridge: Bridge, readonly port: number, private log: (m: string) => void = () => {}) {}

  get mode() {
    return this.owner ? "owner" : "proxy";
  }

  async start(): Promise<void> {
    this.owner = await this.bridge.listen(this.port);
    this.log(this.owner ? `listening on 127.0.0.1:${this.port}` : `port ${this.port} in use, using proxy mode`);
  }

  async send(command: string, params: Record<string, unknown> = {}, timeoutMs = 30_000): Promise<unknown> {
    if (!this.owner) {
      try {
        return await this.remote(command, params, timeoutMs);
      } catch (e) {
        if (!(e instanceof OwnerGoneError)) throw e;
        this.owner = await this.bridge.listen(this.port);
        if (!this.owner) throw new BridgeError(`Port ${this.port} is used by something that is not the Studio bridge.`);
        this.log(`took over 127.0.0.1:${this.port}`);
      }
    }
    return this.bridge.send(command, params, timeoutMs);
  }

  async status(): Promise<unknown> {
    if (this.owner) return { mode: "owner", port: this.port, ...this.bridge.status() };
    try {
      const r = await fetch(`http://127.0.0.1:${this.port}/status`, { headers: { [BRIDGE_HEADER]: "1" } });
      return { mode: "proxy", port: this.port, ...((await r.json()) as object) };
    } catch {
      this.owner = await this.bridge.listen(this.port);
      return { mode: this.mode, port: this.port, ...this.bridge.status() };
    }
  }

  private async remote(command: string, params: Record<string, unknown>, timeoutMs: number) {
    let r: Response;
    try {
      r = await fetch(`http://127.0.0.1:${this.port}/command`, {
        method: "POST",
        headers: { "Content-Type": "application/json", [BRIDGE_HEADER]: "1" },
        body: JSON.stringify({ command, params, timeoutMs }),
        signal: AbortSignal.timeout(timeoutMs + 5_000),
      });
    } catch (e) {
      const err = e as { code?: string; cause?: { code?: string } };
      const code = err.code ?? err.cause?.code;
      if (code === "ECONNREFUSED") throw new OwnerGoneError();
      throw e;
    }
    const body = (await r.json()) as { ok: boolean; result?: unknown; error?: string };
    if (!body.ok) throw new BridgeError(body.error || `bridge error (${r.status})`);
    return body.result;
  }
}

class OwnerGoneError extends Error {}
