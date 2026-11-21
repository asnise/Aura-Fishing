// Compact node reader: walks the live node tree directly (no exportAsync
// JSON_REST_V1), with depth / field / node-count limits so agents get only what
// they need. Used by get_node_info / get_nodes_info / read_my_design when any of
// depth, fields, maxNodes or compact is passed (otherwise the old full output).
// @stability new (Phase 1) - output shape documented in ../README.md
import { getNote } from "./selection.js";

export const ALL_FIELDS = ["box", "fill", "stroke", "radius", "text", "layout", "note"];
const DEFAULTS = { depth: 2, maxNodes: 300, textMax: 200 };

export function wantsCompact(params) {
  return !!params && (params.compact === true || params.depth !== undefined || params.fields !== undefined || params.maxNodes !== undefined);
}

export function compactOptions(params) {
  const p = params || {};
  let fields = p.fields;
  if (typeof fields === "string") fields = fields.split(",").map((s) => s.trim()).filter(Boolean);
  if (!Array.isArray(fields) || fields.length === 0 || fields.includes("all")) fields = ALL_FIELDS;
  return {
    depth: Number.isFinite(p.depth) ? Math.max(0, p.depth) : DEFAULTS.depth,
    maxNodes: Number.isFinite(p.maxNodes) ? Math.max(1, p.maxNodes) : DEFAULTS.maxNodes,
    textMax: Number.isFinite(p.textMax) ? p.textMax : DEFAULTS.textMax,
    skipHidden: p.skipHidden === true,
    fields: new Set(fields),
  };
}

const r = (n) => Math.round(n * 100) / 100;

function hex(c, opacity) {
  const h = (v) => Math.round(v * 255).toString(16).padStart(2, "0");
  const a = opacity === undefined ? 1 : opacity;
  return `#${h(c.r)}${h(c.g)}${h(c.b)}${a < 1 ? h(a) : ""}`;
}

function paintSummary(paints) {
  if (!Array.isArray(paints)) return undefined; // figma.mixed
  const list = paints.filter((p) => p && p.visible !== false);
  if (list.length === 0) return undefined;
  const one = (p) => (p.type === "SOLID" ? hex(p.color, p.opacity) : p.type === "IMAGE" ? "image" : p.type.toLowerCase());
  return list.length === 1 ? one(list[0]) : list.map(one);
}

function addFields(node, out, o) {
  const f = o.fields;
  if (f.has("box") && "width" in node) {
    out.x = r(node.x);
    out.y = r(node.y);
    out.w = r(node.width);
    out.h = r(node.height);
    if ("rotation" in node && node.rotation) out.rotation = r(node.rotation);
  }
  if ("opacity" in node && node.opacity !== 1) out.opacity = r(node.opacity);
  if (f.has("fill") && "fills" in node) {
    const fill = paintSummary(node.fills);
    if (fill !== undefined) out.fill = fill;
  }
  if (f.has("stroke") && "strokes" in node) {
    const stroke = paintSummary(node.strokes);
    if (stroke !== undefined) {
      out.stroke = stroke;
      if (typeof node.strokeWeight === "number") out.strokeWeight = node.strokeWeight;
    }
  }
  if (f.has("radius") && "cornerRadius" in node && typeof node.cornerRadius === "number" && node.cornerRadius > 0) {
    out.radius = node.cornerRadius;
  }
  if (f.has("text") && node.type === "TEXT") {
    const chars = String(node.characters);
    out.text = chars.length > o.textMax ? chars.slice(0, o.textMax) + "..." : chars;
    if (typeof node.fontSize === "number") out.fontSize = node.fontSize;
    if (node.fontName && typeof node.fontName === "object" && node.fontName.family) {
      out.font = `${node.fontName.family} ${node.fontName.style}`;
    }
  }
  if (f.has("layout") && "layoutMode" in node && node.layoutMode && node.layoutMode !== "NONE") {
    out.layout = {
      mode: node.layoutMode,
      gap: node.itemSpacing,
      pad: [node.paddingTop, node.paddingRight, node.paddingBottom, node.paddingLeft],
      main: node.primaryAxisAlignItems,
      cross: node.counterAxisAlignItems,
    };
  }
  if (f.has("note")) {
    const note = getNote(node);
    if (note) out.note = note;
  }
}

function walk(node, o, ctx, level) {
  ctx.count++;
  const out = { id: node.id, name: node.name, type: node.type };
  if (node.visible === false) out.visible = false;
  addFields(node, out, o);
  if ("children" in node && node.children.length > 0) {
    const kids = o.skipHidden ? node.children.filter((c) => c.visible !== false) : node.children;
    if (level >= o.depth) {
      out.childCount = kids.length;
    } else {
      out.children = [];
      for (const child of kids) {
        if (ctx.count >= o.maxNodes) {
          ctx.truncated = true;
          out.childCount = kids.length;
          break;
        }
        out.children.push(walk(child, o, ctx, level + 1));
      }
    }
  }
  return out;
}

/** One node -> compact JSON. Adds `truncated: true` on the root if maxNodes was hit. */
export function compactNode(node, params) {
  const o = compactOptions(params);
  const ctx = { count: 0, truncated: false };
  const out = walk(node, o, ctx, 0);
  out.nodeCount = ctx.count;
  if (ctx.truncated) out.truncated = true;
  return out;
}
