import { randomBytes } from "node:crypto";
import { readFile, realpath, stat } from "node:fs/promises";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { extname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { ProjectFiles, RequestError } from "./files.js";

const { values: options } = parseArgs({ options: {
  workspace: { type: "string" },
  file: { type: "string" },
  desktop: { type: "boolean" },
} });

const workspace = await realpath(resolve(options.workspace ?? process.cwd()));
if (!(await stat(workspace)).isDirectory()) throw new Error("The workspace must be a folder.");

const files = new ProjectFiles(workspace);
await files.start(options.file);
const appDirectory = fileURLToPath(new URL("../", import.meta.url));
const key = randomBytes(24).toString("hex");
const subscribers = new Set<ServerResponse>();
const MAX_REQUEST_BYTES = 5 * 1024 * 1024;
const DESKTOP_IDLE_MS = 120_000;
const staticTypes: Record<string, string> = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".woff2": "font/woff2",
};
let origin: string;
let listeningHost: string;
let lastRequest = Date.now();
let activeRequests = 0;
let heartbeat = Date.now();
let polling = false;

function sendJson(response: ServerResponse, body: unknown, status = 200): void {
  response.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(body));
}

function requestError(error: unknown): { status: number; message: string } {
  if (error instanceof RequestError) return { status: error.status, message: error.message };
  const { code, message } = error as NodeJS.ErrnoException;
  if (code === "ENOENT") return { status: 404, message: "The file was not found." };
  if (code === "EACCES" || code === "EPERM") return { status: 403, message: "Windows denied access to the file." };
  return { status: 500, message: message || String(error) };
}

async function requestBody(request: IncomingMessage): Promise<Record<string, unknown>> {
  if (Number(request.headers["content-length"]) > MAX_REQUEST_BYTES) throw new RequestError(413, "The project is too large.");
  const chunks: Buffer[] = [];
  let size = 0;
  for await (const chunk of request) {
    const bytes = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    size += bytes.length;
    if (size > MAX_REQUEST_BYTES) throw new RequestError(413, "The project is too large.");
    chunks.push(bytes);
  }
  if (size === 0) return {};

  try {
    const data: unknown = JSON.parse(Buffer.concat(chunks).toString("utf8"));
    if (typeof data !== "object" || data === null || Array.isArray(data)) throw new Error();
    return data as Record<string, unknown>;
  } catch {
    throw new RequestError(400, "Send a JSON object.");
  }
}

function optionalText(body: Record<string, unknown>, field: string): string | undefined {
  const value = body[field];
  if (value === undefined) return undefined;
  if (typeof value === "string") return value;
  throw new RequestError(400, `${field} must be text.`);
}

function subscribe(response: ServerResponse): void {
  response.writeHead(200, { "Content-Type": "text/event-stream; charset=utf-8" });
  response.write(`data: ${JSON.stringify(files.state)}\n\n`);
  subscribers.add(response);
  response.on("close", () => {
    subscribers.delete(response);
    lastRequest = Date.now();
  });
}

async function handle(request: IncomingMessage, response: ServerResponse): Promise<void> {
  response.setHeader("Cache-Control", "no-store");
  response.setHeader("Cross-Origin-Resource-Policy", "same-origin");
  response.setHeader("Referrer-Policy", "no-referrer");
  response.setHeader("X-Content-Type-Options", "nosniff");
  response.setHeader("Content-Security-Policy", "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; object-src 'none'; base-uri 'none'; frame-ancestors 'none'");

  if (request.headers.host !== listeningHost || (request.headers.origin && request.headers.origin !== origin)) {
    throw new RequestError(403, "Use the local editor window.");
  }
  if (!request.url?.startsWith("/") || request.url.startsWith("//")) throw new RequestError(400, "Invalid request path.");
  const url = new URL(request.url, origin);
  const route = url.pathname;
  if (route.startsWith("/api/")) {
    if (request.headers["x-editor-key"] !== key && url.searchParams.get("key") !== key) {
      throw new RequestError(403, "Open the editor using its launch URL.");
    }

    if (request.method === "GET") {
      if (route === "/api/session") return sendJson(response, files.state);
      if (route === "/api/samples") return sendJson(response, await files.samples());
      if (route === "/api/events") return subscribe(response);
      if (route === "/api/texture") {
        const path = url.searchParams.get("path");
        if (!path) throw new RequestError(400, "Choose a texture file.");
        const { bytes, mime } = await files.texture(path);
        response.writeHead(200, { "Content-Type": mime, "Content-Length": bytes.length });
        response.end(bytes);
        return;
      }
    }

    if (request.method === "POST") {
      const body = await requestBody(request);
      if (route === "/api/sample") return sendJson(response, await files.run(() => files.sample(optionalText(body, "id") ?? "")));
      if (route === "/api/new") return sendJson(response, await files.run(() => files.newProject(optionalText(body, "name"))));
      if (route === "/api/open") return sendJson(response, await files.run(() => files.open(optionalText(body, "path"))));
      if (route === "/api/save") {
        const result = await files.run(() => files.save(body.project, body.revision, body.saveAs === true, optionalText(body, "path")));
        return sendJson(response, result);
      }
      if (route === "/api/import") return sendJson(response, await files.run(() => files.importTexture(optionalText(body, "path"))));
    }
  } else if (request.method === "GET") {
    const file = route === "/" ? "/ui/index.html" : route;
    if (file === "/model.js" || /^\/(?:ui|render)\/(?:[\w-]+\/)*[\w.-]+\.(?:html|css|js|png|svg|woff2)$/.test(file)) {
      const bytes = await readFile(resolve(appDirectory, file.slice(1)));
      response.writeHead(200, { "Content-Type": staticTypes[extname(file)], "Content-Length": bytes.length });
      response.end(bytes);
      return;
    }
  }
  throw new RequestError(404, "Page not found.");
}

const server = createServer((request, response) => {
  lastRequest = Date.now();
  activeRequests += 1;
  void handle(request, response).catch(error => {
    const { status, message } = requestError(error);
    if (!response.headersSent && !response.destroyed) sendJson(response, { error: message }, status);
    else if (!response.destroyed) response.end();
  }).finally(() => {
    activeRequests -= 1;
    lastRequest = Date.now();
  });
});

server.listen(0, "127.0.0.1", () => {
  const address = server.address();
  if (!address || typeof address === "string") throw new Error("Could not start the local editor.");
  listeningHost = `127.0.0.1:${address.port}`;
  origin = `http://${listeningHost}`;
  console.log(`VFX_EDITOR_URL=${origin}/?key=${key}`);
});

setInterval(() => {
  if (subscribers.size === 0) {
    if (options.desktop && activeRequests === 0 && Date.now() - lastRequest > DESKTOP_IDLE_MS) server.close();
    return;
  }
  if (Date.now() - heartbeat > 15_000) {
    for (const response of subscribers) response.write(": connected\n\n");
    heartbeat = Date.now();
  }
  if (polling) return;
  polling = true;
  void files.run(() => files.poll()).then(changed => {
    if (changed) {
      const event = `data: ${JSON.stringify(files.state)}\n\n`;
      for (const response of subscribers) response.write(event);
    }
  }).catch(error => console.error(error)).finally(() => {
    polling = false;
  });
}, 600).unref();
