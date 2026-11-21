// Usage counter shared by the relay (src/socket.ts, Bun) and the MCP server
// (src/talk_to_figma_mcp/server.ts, Node). Every call is recorded as numbers in
// a JSON file so we can see which tools / commands are used most and by which
// agent. Each process owns one file (no write races):
//   usage/plugin-commands.json  <- relay: every command sent to the Figma plugin (any caller)
//   usage/mcp-tools.json        <- MCP server: every MCP tool call
// Report: node scripts/usage-report.mjs
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "fs";
import * as path from "path";

export interface UsageItem {
  calls: number;
  ok: number;
  errors: number;
  totalMs: number;
  avgMs: number;
  maxMs: number;
  /** response size (relay only): sum / average over successful calls that reported a size */
  totalKB?: number;
  avgKB?: number;
  maxKB?: number;
  sized?: number;
  firstUsed: string;
  lastUsed: string;
  lastError?: string;
  byAgent: Record<string, number>;
}

export interface UsageFile {
  schema: 1;
  kind: string;
  updatedAt: string;
  totals: { calls: number; ok: number; errors: number };
  byAgent: Record<string, number>;
  items: Record<string, UsageItem>;
}

export interface UsageTracker {
  record(name: string, agent: string, ok: boolean, ms: number, error?: string, bytes?: number): void;
  snapshot(): UsageFile;
  flush(): void;
}

function empty(kind: string): UsageFile {
  return { schema: 1, kind, updatedAt: new Date().toISOString(), totals: { calls: 0, ok: 0, errors: 0 }, byAgent: {}, items: {} };
}

export function load(file: string, kind: string): UsageFile {
  try {
    if (existsSync(file)) {
      const data = JSON.parse(readFileSync(file, "utf8"));
      if (data && data.schema === 1 && data.items) return data as UsageFile;
    }
  } catch {
    // corrupt file -> start fresh, never break the tool
  }
  return empty(kind);
}

/** Folder for usage files: --usage-dir=<dir>, env FIGMA_USAGE_DIR, else <repo>/usage. */
export function resolveUsageDir(repoRoot: string, argv: string[] = process.argv): string {
  const arg = argv.find((a) => a.startsWith("--usage-dir="));
  if (arg) return arg.slice("--usage-dir=".length);
  if (process.env.FIGMA_USAGE_DIR) return process.env.FIGMA_USAGE_DIR;
  return path.join(repoRoot, "usage");
}

// flushDelayMs = 0 (default): write on every call. On Windows, MCP clients kill
// the server without running exit handlers, so delayed writes could be lost.
export function createUsageTracker(file: string, kind: string, flushDelayMs = 0): UsageTracker {
  const data = load(file, kind);
  let timer: ReturnType<typeof setTimeout> | null = null;

  function flush() {
    if (timer) {
      clearTimeout(timer);
      timer = null;
    }
    try {
      data.updatedAt = new Date().toISOString();
      mkdirSync(path.dirname(file), { recursive: true });
      const tmp = file + ".tmp";
      writeFileSync(tmp, JSON.stringify(data, null, 2));
      renameSync(tmp, file);
    } catch (e) {
      process.stderr.write(`[usage] could not write ${file}: ${e instanceof Error ? e.message : String(e)}\n`);
    }
  }

  function record(name: string, agent: string, ok: boolean, ms: number, error?: string, bytes?: number) {
    const now = new Date().toISOString();
    const who = agent || "unknown";
    const item = (data.items[name] ||= {
      calls: 0, ok: 0, errors: 0, totalMs: 0, avgMs: 0, maxMs: 0, firstUsed: now, lastUsed: now, byAgent: {},
    });
    item.calls++;
    if (ok) item.ok++;
    else {
      item.errors++;
      if (error) item.lastError = String(error).slice(0, 200);
    }
    // Timing only from successful calls (a 10-minute timeout would wreck the average)
    if (ok) {
      const dur = Math.max(0, Math.round(ms));
      item.totalMs += dur;
      item.maxMs = Math.max(item.maxMs, dur);
      item.avgMs = Math.round(item.totalMs / item.ok);
      if (typeof bytes === "number" && bytes >= 0) {
        const kb = Math.round((bytes / 1024) * 10) / 10;
        item.sized = (item.sized || 0) + 1;
        item.totalKB = Math.round(((item.totalKB || 0) + kb) * 10) / 10;
        item.maxKB = Math.max(item.maxKB || 0, kb);
        item.avgKB = Math.round((item.totalKB / item.sized) * 10) / 10;
      }
    }
    item.lastUsed = now;
    item.byAgent[who] = (item.byAgent[who] || 0) + 1;

    data.totals.calls++;
    if (ok) data.totals.ok++;
    else data.totals.errors++;
    data.byAgent[who] = (data.byAgent[who] || 0) + 1;

    if (flushDelayMs <= 0) flush();
    else if (!timer) timer = setTimeout(flush, flushDelayMs);
  }

  process.on("exit", flush);
  for (const sig of ["SIGINT", "SIGTERM"] as const) {
    process.on(sig, () => {
      flush();
      process.exit(0);
    });
  }

  return { record, snapshot: () => data, flush };
}
