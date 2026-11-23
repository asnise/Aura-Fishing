import { createHash, randomUUID } from "node:crypto";
import { readFile, realpath, rename, stat, unlink, writeFile } from "node:fs/promises";
import { basename, dirname, extname, isAbsolute, relative, resolve, sep } from "node:path";
import { createProject, parseProject, type Asset, type Project } from "../model.js";
import { pickFile } from "./dialogs.js";

const MAX_PROJECT_BYTES = 4 * 1024 * 1024;
const MAX_TEXTURE_BYTES = 64 * 1024 * 1024;
const SAVE_CONFLICT = "The project changed on disk. Reopen it or use Save As to keep your edits.";
const sampleNames = {
  TidalBloom: "Tidal Bloom",
  MoonlitRipple: "Moonlit Ripple",
  NebulaKoi: "Nebula Koi",
};

const textureTypes: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".gif": "image/gif",
};

export interface FileState {
  project: Project;
  path: string | null;
  revision: string | null;
  assetVersion: number;
  error?: string;
}

export class RequestError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function isMissing(error: unknown): boolean {
  return (error as NodeJS.ErrnoException).code === "ENOENT";
}

function localPath(base: string, name: string): string {
  if (!name || name.length > 2048 || /[\u0000-\u001f]/.test(name) || /^[/\\]{2}/.test(name)) {
    throw new RequestError(400, "Choose a local file path.");
  }
  if (process.platform === "win32") {
    const afterDrive = name.replace(/^[A-Za-z]:[/\\]/, "");
    const reserved = /^(?:con|prn|aux|nul|com[1-9¹²³]|lpt[1-9¹²³])(?:\.|$)/i;
    if (/[<>:"|?*]/.test(afterDrive) || afterDrive.split(/[/\\]/).some(part => reserved.test(part))) {
      throw new RequestError(400, "Choose a local file path.");
    }
  }
  return resolve(base, name);
}

function relativePath(base: string, file: string): string {
  return relative(base, file).split(sep).join("/");
}

function samePath(first: string, second: string): boolean {
  return relative(first, second) === "";
}

function isWithin(base: string, file: string): boolean {
  const fromBase = relative(base, file);
  return !isAbsolute(fromBase) && fromBase !== ".." && !fromBase.startsWith(`..${sep}`);
}

function jsonPath(base: string, name: string): string {
  const file = localPath(base, name);
  if (extname(file).toLowerCase() !== ".json") throw new RequestError(400, "Choose a .json project file.");
  return file;
}

async function fileStamp(file: string): Promise<string> {
  try {
    const info = await stat(file);
    return info.isFile() ? `${info.ino}:${info.size}:${info.mtimeMs}:${info.ctimeMs}` : "unavailable";
  } catch {
    return "unavailable";
  }
}

async function projectBytes(file: string): Promise<Buffer> {
  const info = await stat(file);
  if (!info.isFile() || info.size > MAX_PROJECT_BYTES) throw new RequestError(400, "Choose a JSON project under 4 MB.");
  const bytes = await readFile(file);
  if (bytes.length > MAX_PROJECT_BYTES) throw new RequestError(400, "Choose a JSON project under 4 MB.");
  return bytes;
}

function revisionOf(bytes: string | Buffer): string {
  return createHash("sha256").update(bytes).digest("hex");
}

async function readProject(file: string): Promise<{ project: Project; revision: string }> {
  const bytes = await projectBytes(file);
  try {
    return { project: parseProject(JSON.parse(bytes.toString("utf8").replace(/^\uFEFF/, ""))), revision: revisionOf(bytes) };
  } catch (error) {
    throw new RequestError(400, `Invalid particle project. ${errorMessage(error)}`);
  }
}

async function diskRevision(file: string): Promise<string | null> {
  try {
    return revisionOf(await projectBytes(file));
  } catch (error) {
    if (isMissing(error)) return null;
    if (error instanceof RequestError) throw new RequestError(409, SAVE_CONFLICT);
    throw error;
  }
}

async function writeProject(file: string, text: string, expectedRevision: string | null): Promise<void> {
  const temporary = resolve(dirname(file), `.aura-particle-${randomUUID()}.tmp`);
  try {
    await writeFile(temporary, text, { flag: "wx", flush: true });
    if (await diskRevision(file) !== expectedRevision) {
      throw new RequestError(409, SAVE_CONFLICT);
    }
    await rename(temporary, file);
  } finally {
    await unlink(temporary).catch(() => {});
  }
}

async function readTexture(file: string): Promise<{ bytes: Buffer; mime: string }> {
  const mime = textureTypes[extname(file).toLowerCase()];
  if (!mime) throw new RequestError(400, "Choose a PNG, JPEG, WebP, or GIF texture.");
  const info = await stat(file);
  if (!info.isFile() || info.size > MAX_TEXTURE_BYTES) throw new RequestError(400, "Choose an image under 64 MB.");
  const bytes = await readFile(file);
  const signature = bytes.toString("hex", 0, 8);
  const valid = mime === "image/png" && signature === "89504e470d0a1a0a"
    || mime === "image/jpeg" && signature.startsWith("ffd8ff")
    || mime === "image/gif" && /^GIF8[79]a/.test(bytes.toString("ascii", 0, 6))
    || mime === "image/webp" && bytes.toString("ascii", 0, 4) === "RIFF" && bytes.toString("ascii", 8, 12) === "WEBP";
  if (!valid || bytes.length > MAX_TEXTURE_BYTES) throw new RequestError(400, "The file is not a supported image.");
  return { bytes, mime };
}

export class ProjectFiles {
  state: FileState = { project: createProject(), path: null, revision: null, assetVersion: 0 };
  private queue: Promise<unknown> = Promise.resolve();
  private projectStamp = "";
  private assetStamps = new Map<string, string>();
  private imported = new Set<string>();

  constructor(readonly workspace: string) {}

  run<T>(operation: () => Promise<T> | T): Promise<T> {
    const work = this.queue.then(operation);
    this.queue = work.catch(() => {});
    return work;
  }

  async start(file?: string): Promise<void> {
    try {
      if (file) await this.open(file);
      else if ((await this.samples()).some(sample => sample.id === "TidalBloom")) await this.sample("TidalBloom");
    } catch (error) {
      this.state.error = errorMessage(error);
    }
  }

  async samples(): Promise<{ id: string; name: string }[]> {
    const samples = await Promise.all(Object.entries(sampleNames).map(async ([id, name]) => {
      const available = await fileStamp(this.samplePath(id));
      return available === "unavailable" ? null : { id, name };
    }));
    return samples.filter(sample => sample !== null);
  }

  async sample(id: string): Promise<FileState> {
    if (!Object.hasOwn(sampleNames, id)) throw new RequestError(404, "Sample project not found.");
    return this.load(this.samplePath(id));
  }

  newProject(name?: string): FileState {
    this.replace(createProject(name?.trim() || undefined), null, null);
    this.projectStamp = "";
    return this.state;
  }

  async open(path?: string): Promise<FileState | null> {
    const selected = path ?? await pickFile("open", this.base());
    if (selected === null) return null;
    return this.load(jsonPath(this.workspace, selected));
  }

  async save(input: unknown, revision: unknown, saveAs: boolean, path?: string): Promise<FileState | null> {
    let project: Project;
    try {
      project = parseProject(input);
    } catch (error) {
      throw new RequestError(400, errorMessage(error));
    }

    const source = this.state.path;
    const pickerNeeded = path === undefined && (saveAs || source === null);
    const suggestedName = source ? basename(source) : `${project.name.replace(/[^\w -]/g, "_").trim() || "project"}.json`;
    const selected = pickerNeeded ? await pickFile("save", this.base(), suggestedName) : path ?? source;
    if (selected === null) return null;

    const requested = jsonPath(this.workspace, selected);
    const parent = localPath(this.workspace, await realpath(dirname(requested)));
    let file = resolve(parent, basename(requested));
    try {
      file = jsonPath(parent, await realpath(file));
    } catch (error) {
      if (!isMissing(error)) throw error;
    }

    const activePath = source !== null && samePath(source, file);
    const currentRevision = await diskRevision(file);
    if (activePath && (revision !== this.state.revision || revision !== currentRevision)) {
      throw new RequestError(409, SAVE_CONFLICT);
    }
    if (!activePath && currentRevision !== null && !pickerNeeded && revision !== currentRevision) {
      throw new RequestError(409, "A different project already exists at that path. Choose a new name or use the Save As dialog.");
    }

    const previousBase = this.base();
    const destinationBase = dirname(file);
    if (!samePath(previousBase, destinationBase)) {
      project = { ...project, assets: project.assets.map(asset => {
        if (isAbsolute(asset.path)) return asset;
        return { ...asset, path: relativePath(destinationBase, localPath(previousBase, asset.path)) };
      }) };
    }

    const text = `${JSON.stringify(project, null, 2)}\n`;
    if (Buffer.byteLength(text) > MAX_PROJECT_BYTES) throw new RequestError(400, "Choose a JSON project under 4 MB.");
    await writeProject(file, text, currentRevision);
    this.replace(project, file, revisionOf(text));
    this.projectStamp = "";
    await this.loadAssetStamps();
    return this.state;
  }

  async importTexture(path?: string): Promise<{ asset: Asset } | null> {
    const selected = path ?? await pickFile("texture", this.base());
    if (selected === null) return null;
    const file = localPath(this.base(), await realpath(localPath(this.base(), selected)));
    await readTexture(file);
    this.imported.add(file);
    this.assetStamps.set(file, await fileStamp(file));
    return { asset: { id: randomUUID(), name: basename(file, extname(file)), path: relativePath(this.base(), file), matte: "rgba" } };
  }

  async texture(path: string): Promise<{ bytes: Buffer; mime: string }> {
    const requested = localPath(this.base(), path);
    const file = localPath(this.base(), await realpath(requested));
    const declared = this.state.project.assets.some(asset => asset.path === path);
    if (!declared && !isWithin(this.workspace, file) && !isWithin(this.base(), file) && !this.imported.has(file)) {
      throw new RequestError(403, "Import this texture before previewing it.");
    }
    const texture = await readTexture(file);
    if (!this.assetStamps.has(requested)) this.assetStamps.set(requested, await fileStamp(requested));
    return texture;
  }

  async poll(): Promise<boolean> {
    const before = this.state;
    const file = before.path;
    if (file) {
      const stamp = await fileStamp(file);
      if (stamp !== this.projectStamp) {
        this.projectStamp = stamp;
        try {
          const { project, revision } = await readProject(file);
          if (revision !== before.revision || before.error) {
            this.replace(project, file, revision);
            await this.loadAssetStamps();
          }
        } catch (error) {
          const message = isMissing(error) ? "The project file is temporarily unavailable." : errorMessage(error);
          if (before.error !== message) this.state = { ...before, error: message };
        }
      }
    }

    const current = await Promise.all([...this.assetStamps].map(async ([asset, previous]) => {
      const stamp = await fileStamp(asset);
      this.assetStamps.set(asset, stamp);
      return previous !== stamp;
    }));
    if (current.some(Boolean)) this.state = { ...this.state, assetVersion: this.state.assetVersion + 1 };
    return before !== this.state;
  }

  private base(): string {
    return this.state.path ? dirname(this.state.path) : this.workspace;
  }

  private samplePath(id: string): string {
    return resolve(this.workspace, "assets/vfx/aura", id, "project.json");
  }

  private async load(path: string): Promise<FileState> {
    const file = jsonPath(this.workspace, await realpath(path));
    const stamp = await fileStamp(file);
    const { project, revision } = await readProject(file);
    this.replace(project, file, revision);
    this.projectStamp = stamp;
    await this.loadAssetStamps();
    return this.state;
  }

  private replace(project: Project, path: string | null, revision: string | null): void {
    this.state = { project, path, revision, assetVersion: this.state.assetVersion + 1 };
    this.assetStamps.clear();
    this.imported.clear();
  }

  private async loadAssetStamps(): Promise<void> {
    await Promise.all(this.state.project.assets.map(async asset => {
      try {
        const file = localPath(this.base(), asset.path);
        this.assetStamps.set(file, await fileStamp(file));
      } catch {
        // Missing or unsupported paths stay editable in the project.
      }
    }));
  }
}
