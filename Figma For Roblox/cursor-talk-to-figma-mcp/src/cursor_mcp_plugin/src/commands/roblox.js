// Aura Fishing fork: Roblox-oriented tree export (consumed by src/talk_to_figma_mcp/roblox.ts).
// @stability stable (fork) - used by export_to_roblox; output format is read by talk_to_figma_mcp/roblox.ts

import { customBase64Encode } from "../core/utils.js";

// ===========================================================================
// Roblox export (Aura Fishing fork)
// Serialises a node tree into a compact, Roblox-oriented JSON that the MCP
// server converts into Luau UI code. Coordinates are absolute (canvas space).
// ===========================================================================

export const ROBLOX_VECTOR_TYPES = {
  VECTOR: true, STAR: true, POLYGON: true, BOOLEAN_OPERATION: true, LINE: true,
};

export function rbxColor(c, opacity) {
  return {
    r: Math.round(c.r * 255),
    g: Math.round(c.g * 255),
    b: Math.round(c.b * 255),
    a: (c.a === undefined ? 1 : c.a) * (opacity === undefined ? 1 : opacity),
  };
}

export function rbxPaints(paints) {
  if (!paints || paints === figma.mixed || !Array.isArray(paints)) return [];
  var out = [];
  for (var i = 0; i < paints.length; i++) {
    var p = paints[i];
    if (p.visible === false) continue;
    if (p.type === "SOLID") {
      out.push({ type: "SOLID", color: rbxColor(p.color, p.opacity) });
    } else if (p.type === "GRADIENT_LINEAR" || p.type === "GRADIENT_RADIAL" || p.type === "GRADIENT_ANGULAR" || p.type === "GRADIENT_DIAMOND") {
      var stops = [];
      for (var j = 0; j < p.gradientStops.length; j++) {
        var st = p.gradientStops[j];
        stops.push({ position: st.position, color: rbxColor(st.color, p.opacity) });
      }
      out.push({ type: p.type, stops: stops, transform: p.gradientTransform });
    } else if (p.type === "IMAGE") {
      out.push({ type: "IMAGE", imageHash: p.imageHash, scaleMode: p.scaleMode, opacity: p.opacity === undefined ? 1 : p.opacity });
    }
  }
  return out;
}

export function rbxIsVectorOnly(node) {
  if (ROBLOX_VECTOR_TYPES[node.type]) return true;
  if (node.type === "ELLIPSE") return true;
  if (!("children" in node) || node.children.length === 0) return false;
  if (node.type !== "GROUP" && node.type !== "FRAME" && node.type !== "INSTANCE" && node.type !== "COMPONENT") return false;
  var hasVector = false;
  for (var i = 0; i < node.children.length; i++) {
    var c = node.children[i];
    if (c.type === "TEXT") return false;
    if (!rbxIsVectorOnly(c)) return false;
    if (ROBLOX_VECTOR_TYPES[c.type]) hasVector = true;
  }
  return hasVector;
}

export function rbxSerialize(node, depth, maxDepth, counter) {
  counter.count++;
  var t = node.absoluteTransform;
  var w = "width" in node ? node.width : 0;
  var h = "height" in node ? node.height : 0;
  var out = {
    id: node.id,
    name: node.name,
    type: node.type,
    visible: node.visible !== false,
    x: t ? t[0][2] : 0,
    y: t ? t[1][2] : 0,
    width: w,
    height: h,
    rotation: "rotation" in node ? node.rotation : 0,
    opacity: "opacity" in node ? node.opacity : 1,
  };
  if (t) {
    out.centerX = t[0][0] * w / 2 + t[0][1] * h / 2 + t[0][2];
    out.centerY = t[1][0] * w / 2 + t[1][1] * h / 2 + t[1][2];
  }
  if ("fills" in node) out.fills = rbxPaints(node.fills);
  if ("strokes" in node) {
    out.strokes = rbxPaints(node.strokes);
    if (out.strokes.length > 0) out.strokeWeight = node.strokeWeight === figma.mixed ? 1 : node.strokeWeight;
  }
  if ("cornerRadius" in node) {
    out.cornerRadius = node.cornerRadius === figma.mixed ? (node.topLeftRadius || 0) : node.cornerRadius;
  }
  if ("clipsContent" in node) out.clipsContent = node.clipsContent;
  if ("effects" in node && node.effects) {
    var fx = [];
    for (var e = 0; e < node.effects.length; e++) {
      var ef = node.effects[e];
      if (ef.visible === false) continue;
      fx.push({ type: ef.type, radius: ef.radius, color: ef.color ? rbxColor(ef.color) : null, offset: ef.offset || null });
    }
    if (fx.length) out.effects = fx;
  }
  if ("layoutMode" in node && node.layoutMode && node.layoutMode !== "NONE") {
    out.layout = {
      mode: node.layoutMode,
      wrap: node.layoutWrap,
      itemSpacing: node.itemSpacing,
      paddingLeft: node.paddingLeft, paddingRight: node.paddingRight,
      paddingTop: node.paddingTop, paddingBottom: node.paddingBottom,
      primaryAlign: node.primaryAxisAlignItems,
      counterAlign: node.counterAxisAlignItems,
    };
  }
  if ("layoutPositioning" in node) out.layoutPositioning = node.layoutPositioning;
  if ("constraints" in node && node.constraints) out.constraints = node.constraints;
  if (node.type === "ELLIPSE") out.isCircle = Math.abs(w - h) < 0.5 && node.arcData && node.arcData.endingAngle - node.arcData.startingAngle >= 6.28 && node.arcData.innerRadius === 0;
  if (node.type === "TEXT") {
    var fontName = node.fontName === figma.mixed ? node.getRangeFontName(0, 1) : node.fontName;
    var fontSize = node.fontSize === figma.mixed ? node.getRangeFontSize(0, 1) : node.fontSize;
    var textFills = node.fills === figma.mixed ? node.getRangeFills(0, 1) : node.fills;
    out.text = {
      characters: node.characters,
      fontFamily: fontName.family,
      fontStyle: fontName.style,
      fontSize: fontSize,
      alignH: node.textAlignHorizontal,
      alignV: node.textAlignVertical,
      autoResize: node.textAutoResize,
      fills: rbxPaints(textFills),
    };
  }

  var vectorOnly = rbxIsVectorOnly(node) && !(node.type === "ELLIPSE" && out.isCircle && out.fills && out.fills.length > 0 && out.fills[0].type === "SOLID");
  out.rasterize = vectorOnly || /\[img\]/i.test(node.name);

  if (!out.rasterize && "children" in node && depth < maxDepth) {
    out.children = [];
    for (var i = 0; i < node.children.length; i++) {
      var child = node.children[i];
      if (child.isMask) continue;
      out.children.push(rbxSerialize(child, depth + 1, maxDepth, counter));
    }
  }
  return out;
}

export async function getRobloxTree(params) {
  var node = null;
  if (params && params.nodeId) {
    node = await figma.getNodeByIdAsync(params.nodeId);
    if (!node) throw new Error("Node not found with ID: " + params.nodeId);
  } else {
    var sel = figma.currentPage.selection;
    if (!sel || sel.length === 0) throw new Error("Nothing selected. Select a frame in Figma or pass nodeId.");
    node = sel[0];
  }
  if (!("absoluteTransform" in node)) throw new Error("Node is not a visual layer: " + node.type);
  var counter = { count: 0 };
  var tree = rbxSerialize(node, 0, (params && params.maxDepth) || 40, counter);
  return { root: tree, nodeCount: counter.count, fileName: figma.root.name };
}

export async function getImageByHash(params) {
  if (!params || !params.hash) throw new Error("Missing hash parameter");
  var image = figma.getImageByHash(params.hash);
  if (!image) throw new Error("Image not found for hash " + params.hash);
  var bytes = await image.getBytesAsync();
  return { imageData: customBase64Encode(bytes), mimeType: "image/png" };
}

export const commands = {
  get_roblox_tree: getRobloxTree,
  get_image_by_hash: getImageByHash,
};
