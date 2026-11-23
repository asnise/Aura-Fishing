import type { Asset, Project } from "../model.js";

export type FileState = {
  project: Project;
  path: string | null;
  revision: string | null;
  assetVersion: number;
  error?: string;
};

export type Sample = { id: string; name: string };

export class ApiError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

const key = new URLSearchParams(location.search).get("key") ?? "";

export async function request<T>(url: string, body?: object): Promise<T> {
  const headers = new Headers();
  if (key) headers.set("X-Editor-Key", key);
  if (body !== undefined) headers.set("Content-Type", "application/json");

  const response = await fetch(url, {
    headers,
    method: body === undefined ? "GET" : "POST",
    body: body === undefined ? undefined : JSON.stringify(body),
    cache: "no-store",
  });

  const result = await response.json() as T | { error?: string; message?: string } | null;
  if (!response.ok) {
    const issue = result as { error?: string; message?: string } | null;
    throw new ApiError(response.status, issue?.error ?? issue?.message ?? `Request failed (${response.status})`);
  }
  return result as T;
}

export function textureUrl(asset: Asset, version: number): string {
  const query = new URLSearchParams({ path: asset.path, v: String(version) });
  if (key) query.set("key", key);
  return `/api/texture?${query.toString()}`;
}

export function eventsUrl(): string {
  const query = new URLSearchParams({ key });
  return `/api/events?${query.toString()}`;
}
