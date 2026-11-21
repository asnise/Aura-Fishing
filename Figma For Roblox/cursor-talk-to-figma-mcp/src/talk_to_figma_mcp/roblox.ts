// Figma -> Roblox UI converter (Aura Fishing fork).
// Input: the JSON tree produced by the plugin command `get_roblox_tree`.
// Output: a Luau ModuleScript that builds the UI with Instance.new, plus a list of image
// assets (PNG) that must be uploaded to Roblox and mapped in the module's `Images` table.
//
// Naming conventions designers can use in Figma layer names:
//   [btn]  -> TextButton / ImageButton            (also names starting with "Btn" or "Button")
//   [img]  -> rasterise the whole layer to one image
//   [skip] -> do not export this layer
//   [scroll] -> ScrollingFrame

export interface RbxColor { r: number; g: number; b: number; a: number }
export interface RbxPaint {
  type: string;
  color?: RbxColor;
  stops?: { position: number; color: RbxColor }[];
  transform?: number[][];
  imageHash?: string;
  scaleMode?: string;
  opacity?: number;
}
export interface RbxNode {
  id: string;
  name: string;
  type: string;
  visible: boolean;
  x: number;
  y: number;
  width: number;
  height: number;
  centerX?: number;
  centerY?: number;
  rotation: number;
  opacity: number;
  fills?: RbxPaint[];
  strokes?: RbxPaint[];
  strokeWeight?: number;
  cornerRadius?: number;
  clipsContent?: boolean;
  effects?: { type: string; radius?: number; color?: RbxColor | null }[];
  layout?: {
    mode: "HORIZONTAL" | "VERTICAL";
    wrap?: string;
    itemSpacing: number;
    paddingLeft: number; paddingRight: number; paddingTop: number; paddingBottom: number;
    primaryAlign: string;
    counterAlign: string;
  };
  layoutPositioning?: string;
  isCircle?: boolean;
  rasterize?: boolean;
  text?: {
    characters: string;
    fontFamily: string;
    fontStyle: string;
    fontSize: number;
    alignH: string;
    alignV: string;
    autoResize: string;
    fills: RbxPaint[];
  };
  children?: RbxNode[];
}

export type SizeMode = "scale" | "offset";

export interface ConvertOptions {
  moduleName: string;
  sizeMode: SizeMode; // scale = responsive (default), offset = pixel-perfect
  rootFit: "aspect" | "stretch" | "offset"; // how the root fills its parent
  includeHidden: boolean;
  existingImages?: Record<string, string>; // key -> rbxassetid, preserved across re-exports
}

export interface AssetRequest {
  key: string; // file name without extension, also the key in the Luau Images table
  nodeId: string;
  kind: "render" | "hash";
  hash?: string;
}

export interface ConvertResult {
  luau: string;
  assets: AssetRequest[];
  warnings: string[];
  instanceCount: number;
}

// --- helpers -------------------------------------------------------------------------

const FONT_FAMILIES: Record<string, string> = {
  "builder sans": "BuilderSans",
  "gotham": "GothamSSm",
  "gotham ssm": "GothamSSm",
  "montserrat": "Montserrat",
  "roboto": "Roboto",
  "roboto mono": "RobotoMono",
  "roboto condensed": "RobotoCondensed",
  "source sans pro": "SourceSansPro",
  "source sans 3": "SourceSansPro",
  "nunito": "Nunito",
  "oswald": "Oswald",
  "fredoka one": "FredokaOne",
  "fredoka": "FredokaOne",
  "luckiest guy": "LuckiestGuy",
  "bangers": "Bangers",
  "arial": "Arial",
  "arimo": "Arimo",
  "ubuntu": "Ubuntu",
  "inconsolata": "Inconsolata",
  "press start 2p": "PressStart2P",
  "merriweather": "Merriweather",
  "titillium web": "TitilliumWeb",
  "jura": "Jura",
  "kalam": "Kalam",
  "denk one": "DenkOne",
  "indie flower": "IndieFlower",
  "patrick hand": "PatrickHand",
  "permanent marker": "PermanentMarker",
  "creepster": "Creepster",
  "michroma": "Michroma",
  "amatic sc": "AmaticSC",
  "oxanium": "Oxanium",
  "sarpanch": "Sarpanch",
  "special elite": "SpecialElite",
};
const DEFAULT_FONT = "BuilderSans";

function fontWeight(style: string): string {
  const s = style.toLowerCase().replace(/\s|-/g, "");
  if (s.includes("thin")) return "Thin";
  if (s.includes("extralight") || s.includes("ultralight")) return "ExtraLight";
  if (s.includes("semibold") || s.includes("demibold")) return "SemiBold";
  if (s.includes("extrabold") || s.includes("ultrabold")) return "ExtraBold";
  if (s.includes("black") || s.includes("heavy")) return "Heavy";
  if (s.includes("bold")) return "Bold";
  if (s.includes("medium")) return "Medium";
  if (s.includes("light")) return "Light";
  return "Regular";
}

const num = (n: number) => {
  const v = Math.round(n * 10000) / 10000;
  return Object.is(v, -0) ? "0" : String(v);
};
const px = (n: number) => String(Math.round(n));
const luaString = (s: string) =>
  '"' + s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r?\n/g, "\\n") + '"';
const color3 = (c: RbxColor) => `Color3.fromRGB(${c.r}, ${c.g}, ${c.b})`;
const transparency = (alpha: number) => num(Math.min(1, Math.max(0, 1 - alpha)));

function cleanName(name: string): string {
  const stripped = name.replace(/\[(btn|img|skip|scroll)\]/gi, "").trim();
  const n = stripped.replace(/[^A-Za-z0-9_]+/g, "_").replace(/^_+|_+$/g, "");
  if (!n) return "Layer";
  return /^[0-9]/.test(n) ? "_" + n : n;
}

function isButton(node: RbxNode): boolean {
  return /\[btn\]/i.test(node.name) || /^(btn|button)/i.test(node.name.trim());
}

// --- converter -------------------------------------------------------------------------

export function convertToRoblox(root: RbxNode, opts: ConvertOptions): ConvertResult {
  const lines: string[] = [];
  const assets: AssetRequest[] = [];
  const assetKeys = new Set<string>();
  const warnings: string[] = [];
  const usedRefNames = new Map<string, number>();
  let varCounter = 0;
  const scale = opts.sizeMode === "scale";

  const emit = (s: string) => lines.push("\t" + s);

  function refName(node: RbxNode): string {
    const base = cleanName(node.name);
    const count = (usedRefNames.get(base) || 0) + 1;
    usedRefNames.set(base, count);
    return count === 1 ? base : `${base}_${count}`;
  }

  function addAsset(node: RbxNode, kind: "render" | "hash", hash?: string): string {
    let key = cleanName(node.name);
    let i = 2;
    while (assetKeys.has(key)) key = `${cleanName(node.name)}_${i++}`;
    assetKeys.add(key);
    assets.push({ key, nodeId: node.id, kind, hash });
    return key;
  }

  // Children of an auto-layout frame are sized relative to the area inside UIPadding.
  function contentBox(node: RbxNode) {
    const L = node.layout;
    if (!L) return { x: node.x, y: node.y, w: node.width, h: node.height };
    return {
      x: node.x + (L.paddingLeft || 0),
      y: node.y + (L.paddingTop || 0),
      w: Math.max(1, node.width - (L.paddingLeft || 0) - (L.paddingRight || 0)),
      h: Math.max(1, node.height - (L.paddingTop || 0) - (L.paddingBottom || 0)),
    };
  }

  // position/size of `node` inside a parent box (absolute canvas coords)
  function placement(node: RbxNode, parent: { x: number; y: number; w: number; h: number } | null, inLayout: boolean) {
    const rotated = Math.abs(node.rotation) > 0.01;
    const props: string[] = [];
    if (!parent) return props;
    const pw = parent.w || 1;
    const ph = parent.h || 1;
    if (scale) {
      props.push(`Size = UDim2.fromScale(${num(node.width / pw)}, ${num(node.height / ph)})`);
    } else {
      props.push(`Size = UDim2.fromOffset(${px(node.width)}, ${px(node.height)})`);
    }
    if (inLayout) return props;
    if (rotated && node.centerX !== undefined && node.centerY !== undefined) {
      const cx = node.centerX - parent.x;
      const cy = node.centerY - parent.y;
      props.push(`AnchorPoint = Vector2.new(0.5, 0.5)`);
      props.push(scale
        ? `Position = UDim2.fromScale(${num(cx / pw)}, ${num(cy / ph)})`
        : `Position = UDim2.fromOffset(${px(cx)}, ${px(cy)})`);
      props.push(`Rotation = ${num(-node.rotation)}`);
    } else {
      const rx = node.x - parent.x;
      const ry = node.y - parent.y;
      props.push(scale
        ? `Position = UDim2.fromScale(${num(rx / pw)}, ${num(ry / ph)})`
        : `Position = UDim2.fromOffset(${px(rx)}, ${px(ry)})`);
    }
    return props;
  }

  function emitInstance(v: string, className: string, props: string[], parentVar: string, ref: string) {
    emit(`local ${v} = Instance.new("${className}")`);
    emit(`${v}.Name = ${luaString(ref)}`);
    for (const p of props) emit(`${v}.${p}`);
    emit(`${v}.Parent = ${parentVar}`);
    emit(`refs[${luaString(ref)}] = ${v}`);
  }

  function child(className: string, parentVar: string, props: string[]) {
    const v = `c${++varCounter}`;
    emit(`local ${v} = Instance.new("${className}")`);
    for (const p of props) emit(`${v}.${p}`);
    emit(`${v}.Parent = ${parentVar}`);
  }

  function gradientChild(paint: RbxPaint, parentVar: string) {
    const stops = (paint.stops || []).slice(0, 20);
    if (stops.length === 0) return;
    if (paint.type !== "GRADIENT_LINEAR") warnings.push(`${paint.type} approximated as linear gradient`);
    const colorKps = stops.map(s => `ColorSequenceKeypoint.new(${num(s.position)}, ${color3(s.color)})`);
    const transKps = stops.map(s => `NumberSequenceKeypoint.new(${num(s.position)}, ${transparency(s.color.a)})`);
    if (stops[0].position > 0) {
      colorKps.unshift(`ColorSequenceKeypoint.new(0, ${color3(stops[0].color)})`);
      transKps.unshift(`NumberSequenceKeypoint.new(0, ${transparency(stops[0].color.a)})`);
    }
    const last = stops[stops.length - 1];
    if (last.position < 1) {
      colorKps.push(`ColorSequenceKeypoint.new(1, ${color3(last.color)})`);
      transKps.push(`NumberSequenceKeypoint.new(1, ${transparency(last.color.a)})`);
    }
    let rotation = 0;
    if (paint.transform) {
      const [[a], [c]] = paint.transform as any;
      rotation = Math.round((Math.atan2(c, a) * 180) / Math.PI);
    }
    child("UIGradient", parentVar, [
      `Color = ColorSequence.new({ ${colorKps.join(", ")} })`,
      `Transparency = NumberSequence.new({ ${transKps.join(", ")} })`,
      `Rotation = ${rotation}`,
    ]);
  }

  // Decorations shared by frames/images/text: corner, stroke, gradient
  function decorations(node: RbxNode, v: string, isText: boolean) {
    if (node.isCircle) {
      child("UICorner", v, [`CornerRadius = UDim.new(0.5, 0)`]);
    } else if (node.cornerRadius && node.cornerRadius > 0) {
      const r = Math.min(node.cornerRadius, Math.min(node.width, node.height) / 2);
      child("UICorner", v, [`CornerRadius = UDim.new(0, ${px(r)})`]);
    }
    const stroke = (node.strokes || []).find(p => p.type === "SOLID");
    if (stroke && stroke.color && (node.strokeWeight || 0) > 0) {
      child("UIStroke", v, [
        `Color = ${color3(stroke.color)}`,
        `Transparency = ${transparency(stroke.color.a)}`,
        `Thickness = ${num(node.strokeWeight || 1)}`,
        `ApplyStrokeMode = Enum.ApplyStrokeMode.${isText ? "Contextual" : "Border"}`,
      ]);
    }
    if (node.effects && node.effects.some(e => e.type === "DROP_SHADOW" || e.type === "INNER_SHADOW" || e.type === "LAYER_BLUR")) {
      warnings.push(`"${node.name}": shadows/blur are not converted (add a shadow image or UIStroke manually)`);
    }
  }

  function layoutChild(node: RbxNode, v: string) {
    const L = node.layout!;
    const horizontal = L.mode === "HORIZONTAL";
    const axisSize = horizontal ? node.width : node.height;
    const spacing = scale ? `UDim.new(${num(L.itemSpacing / (axisSize || 1))}, 0)` : `UDim.new(0, ${px(L.itemSpacing)})`;
    const primary = (a: string) => a === "CENTER" ? "Center" : a === "MAX" ? (horizontal ? "Right" : "Bottom") : (horizontal ? "Left" : "Top");
    const counter = (a: string) => a === "CENTER" ? "Center" : a === "MAX" ? (horizontal ? "Bottom" : "Right") : (horizontal ? "Top" : "Left");
    const hAlign = horizontal ? primary(L.primaryAlign) : counter(L.counterAlign);
    const vAlign = horizontal ? counter(L.counterAlign) : primary(L.primaryAlign);
    const props = [
      `FillDirection = Enum.FillDirection.${horizontal ? "Horizontal" : "Vertical"}`,
      `SortOrder = Enum.SortOrder.LayoutOrder`,
      `Padding = ${spacing}`,
      `HorizontalAlignment = Enum.HorizontalAlignment.${hAlign}`,
      `VerticalAlignment = Enum.VerticalAlignment.${vAlign}`,
    ];
    if (L.wrap === "WRAP") props.push(`Wraps = true`);
    if (L.primaryAlign === "SPACE_BETWEEN") {
      props.push(horizontal ? `HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween` : `VerticalFlex = Enum.UIFlexAlignment.SpaceBetween`);
    }
    child("UIListLayout", v, props);
    const pad = (val: number, total: number) => scale ? `UDim.new(${num(val / (total || 1))}, 0)` : `UDim.new(0, ${px(val)})`;
    if (L.paddingLeft || L.paddingRight || L.paddingTop || L.paddingBottom) {
      child("UIPadding", v, [
        `PaddingLeft = ${pad(L.paddingLeft, node.width)}`,
        `PaddingRight = ${pad(L.paddingRight, node.width)}`,
        `PaddingTop = ${pad(L.paddingTop, node.height)}`,
        `PaddingBottom = ${pad(L.paddingBottom, node.height)}`,
      ]);
    }
  }

  function textProps(node: RbxNode): string[] {
    const t = node.text!;
    const family = FONT_FAMILIES[t.fontFamily.toLowerCase()];
    if (!family) warnings.push(`Font "${t.fontFamily}" has no Roblox match -> ${DEFAULT_FONT} (edit FONT_FAMILIES in roblox.ts)`);
    const italic = /italic/i.test(t.fontStyle);
    const fill = (t.fills || []).find(p => p.type === "SOLID");
    const alignH = t.alignH === "CENTER" ? "Center" : t.alignH === "RIGHT" ? "Right" : "Left";
    const alignV = t.alignV === "CENTER" ? "Center" : t.alignV === "BOTTOM" ? "Bottom" : "Top";
    const props = [
      `Text = ${luaString(t.characters)}`,
      `FontFace = Font.new("rbxasset://fonts/families/${family || DEFAULT_FONT}.json", Enum.FontWeight.${fontWeight(t.fontStyle)}, Enum.FontStyle.${italic ? "Italic" : "Normal"})`,
      `TextColor3 = ${fill && fill.color ? color3(fill.color) : "Color3.new(0, 0, 0)"}`,
      `TextTransparency = ${fill && fill.color ? transparency(fill.color.a) : "0"}`,
      `TextXAlignment = Enum.TextXAlignment.${alignH}`,
      `TextYAlignment = Enum.TextYAlignment.${alignV}`,
      `TextWrapped = true`,
    ];
    if (scale) props.push(`TextScaled = true`);
    else props.push(`TextSize = ${px(t.fontSize)}`);
    if ((t.fills || []).some(p => p.type.startsWith("GRADIENT"))) warnings.push(`"${node.name}": gradient text uses first solid colour only`);
    return props;
  }

  function convert(node: RbxNode, parentVar: string, parentBox: { x: number; y: number; w: number; h: number } | null, inLayout: boolean, order: number) {
    if (/\[skip\]/i.test(node.name)) return;
    if (!node.visible && !opts.includeHidden) return;

    const v = `n${++varCounter}`;
    const ref = refName(node);
    const props: string[] = [];
    const fills = node.fills || [];
    const solid = fills.filter(p => p.type === "SOLID");
    const image = fills.find(p => p.type === "IMAGE");
    const gradient = fills.find(p => p.type.startsWith("GRADIENT"));
    const button = isButton(node);
    const hasChildren = !!(node.children && node.children.length);

    let className: string;
    let assetKey: string | null = null;
    let isText = false;

    if (node.rasterize) {
      className = button ? "ImageButton" : "ImageLabel";
      assetKey = addAsset(node, "render");
    } else if (node.type === "TEXT") {
      className = button ? "TextButton" : "TextLabel";
      isText = true;
    } else if (image && image.imageHash) {
      className = button ? "ImageButton" : "ImageLabel";
      assetKey = addAsset(node, "hash", image.imageHash);
    } else if (/\[scroll\]/i.test(node.name)) {
      className = "ScrollingFrame";
    } else if (button) {
      className = "TextButton";
    } else if (hasChildren && node.opacity < 0.999) {
      className = "CanvasGroup";
    } else {
      className = "Frame";
    }

    props.push(...placement(node, parentBox, inLayout));
    if (inLayout) props.push(`LayoutOrder = ${order}`);
    props.push(`ZIndex = ${order}`);
    if (!node.visible) props.push(`Visible = false`);
    props.push(`BorderSizePixel = 0`);

    // background
    const nodeAlpha = className === "CanvasGroup" ? 1 : node.opacity;
    if (assetKey) {
      props.push(`Image = Images[${luaString(assetKey)}] or ""`);
      props.push(`ImageTransparency = ${transparency(nodeAlpha * (image?.opacity ?? 1))}`);
      const sm = image?.scaleMode;
      props.push(`ScaleType = Enum.ScaleType.${sm === "FIT" ? "Fit" : sm === "TILE" ? "Tile" : sm === "CROP" || sm === "FILL" ? "Crop" : "Stretch"}`);
    }
    if (!node.rasterize && solid.length > 0 && solid[0].color && node.type !== "TEXT") {
      if (solid.length > 1) warnings.push(`"${node.name}": multiple fills, using the top-most solid fill`);
      const top = solid[solid.length - 1].color!;
      props.push(`BackgroundColor3 = ${color3(top)}`);
      props.push(`BackgroundTransparency = ${transparency(top.a * nodeAlpha)}`);
    } else if (!node.rasterize && gradient && node.type !== "TEXT") {
      props.push(`BackgroundColor3 = Color3.new(1, 1, 1)`);
      props.push(`BackgroundTransparency = ${transparency(nodeAlpha)}`);
    } else {
      props.push(`BackgroundTransparency = 1`);
    }
    if (className === "CanvasGroup") props.push(`GroupTransparency = ${transparency(node.opacity)}`);
    if (node.clipsContent && hasChildren) props.push(`ClipsDescendants = true`);
    if (className === "TextButton" && !isText) props.push(`Text = ""`);
    if (className === "TextButton" || className === "ImageButton") props.push(`AutoButtonColor = true`);
    if (className === "ScrollingFrame") {
      props.push(`ScrollBarThickness = 6`, `AutomaticCanvasSize = Enum.AutomaticSize.Y`, `CanvasSize = UDim2.new()`);
    }
    if (isText) props.push(...textProps(node));
    if (node.type === "LINE" && !node.rasterize) warnings.push(`"${node.name}": line exported as image`);

    emitInstance(v, className, props, parentVar, ref);

    if (isText && scale) {
      child("UITextSizeConstraint", v, [`MaxTextSize = ${px(node.text!.fontSize)}`, `MinTextSize = 6`]);
    }
    if (!node.rasterize) {
      decorations(node, v, isText);
      if (gradient && node.type !== "TEXT") gradientChild(gradient, v);
    }

    if (hasChildren && !node.rasterize) {
      const useLayout = !!node.layout;
      if (useLayout) layoutChild(node, v);
      const box = contentBox(node);
      let i = 0;
      for (const c of node.children!) {
        i++;
        const absoluteInLayout = c.layoutPositioning === "ABSOLUTE";
        if (useLayout && absoluteInLayout) {
          warnings.push(`"${c.name}": absolute-positioned child inside auto-layout will follow the UIListLayout in Roblox`);
        }
        convert(c, v, box, useLayout, i);
      }
    }
  }

  // --- root ---
  const rootVar = "root";
  const rootRef = refName(root);
  const rootProps: string[] = [];
  const rootIsButton = isButton(root);
  rootProps.push(`BorderSizePixel = 0`);
  if (opts.rootFit === "offset") {
    rootProps.push(`AnchorPoint = Vector2.new(0.5, 0.5)`, `Position = UDim2.fromScale(0.5, 0.5)`, `Size = UDim2.fromOffset(${px(root.width)}, ${px(root.height)})`);
  } else {
    rootProps.push(`AnchorPoint = Vector2.new(0.5, 0.5)`, `Position = UDim2.fromScale(0.5, 0.5)`, `Size = UDim2.fromScale(1, 1)`);
  }
  const rootSolid = (root.fills || []).filter(p => p.type === "SOLID");
  if (rootSolid.length && rootSolid[rootSolid.length - 1].color) {
    const c = rootSolid[rootSolid.length - 1].color!;
    rootProps.push(`BackgroundColor3 = ${color3(c)}`, `BackgroundTransparency = ${transparency(c.a * root.opacity)}`);
  } else {
    rootProps.push(`BackgroundTransparency = 1`);
  }
  if (root.clipsContent) rootProps.push(`ClipsDescendants = true`);

  // Root: if the root itself is an image/rasterised layer, wrap it in a frame so children logic stays simple.
  const rootNode: RbxNode = { ...root };

  lines.push(`--!nonstrict`);
  lines.push(`-- AUTO-GENERATED by FigmaRoblox from Figma layer "${root.name.replace(/\n/g, " ")}" (${root.id}).`);
  lines.push(`-- Re-exporting overwrites this file, except the rbxassetid values in Images.`);
  lines.push(`-- Usage:`);
  lines.push(`--   local build = require(path.to.${opts.moduleName})`);
  lines.push(`--   local ui = build(screenGui)            -- returns { Root = Frame, Refs = { [layerName] = Instance } }`);
  lines.push(`--   ui.Refs.PlayButton.Activated:Connect(function() ... end)`);
  lines.push(``);
  lines.push(`-- Upload the PNGs in assets/ui/${opts.moduleName}/ to Roblox, then paste the ids here.`);
  lines.push(`local Images = {`);
  const imagesInsertAt = lines.length;
  lines.push(`}`);
  lines.push(``);
  lines.push(`return function(parent: Instance?)`);
  lines.push(`\tlocal refs = {}`);
  emitInstance(rootVar, rootIsButton ? "TextButton" : "Frame", rootProps, "parent", rootRef);
  if (opts.rootFit === "aspect") {
    child("UIAspectRatioConstraint", rootVar, [`AspectRatio = ${num(root.width / (root.height || 1))}`, `DominantAxis = Enum.DominantAxis.Width`, `AspectType = Enum.AspectType.FitWithinMaxSize`]);
  }
  if (rootIsButton) emit(`${rootVar}.Text = ""`);
  if (rootNode.rasterize) {
    // whole root is one image
    const key = addAsset(rootNode, "render");
    child("ImageLabel", rootVar, [`Size = UDim2.fromScale(1, 1)`, `BackgroundTransparency = 1`, `Image = Images[${luaString(key)}] or ""`]);
  } else {
    decorations(rootNode, rootVar, false);
    const rootGradient = (root.fills || []).find(p => p.type.startsWith("GRADIENT"));
    if (rootGradient) gradientChild(rootGradient, rootVar);
    if (root.layout) layoutChild(root, rootVar);
    const box = contentBox(root);
    let i = 0;
    for (const c of root.children || []) {
      i++;
      convert(c, rootVar, box, !!root.layout, i);
    }
  }
  lines.push(`\treturn { Root = root, Refs = refs }`);
  lines.push(`end`);

  const imageLines = assets.map(a => {
    const existing = opts.existingImages?.[a.key];
    return `\t[${luaString(a.key)}] = ${luaString(existing || "rbxassetid://0")}, -- ${a.kind === "hash" ? "image fill" : "rendered layer"} ${a.nodeId}`;
  });
  lines.splice(imagesInsertAt, 0, ...imageLines);

  const instanceCount = lines.filter(l => /Instance\.new\(/.test(l)).length;
  return { luau: lines.join("\n") + "\n", assets, warnings: Array.from(new Set(warnings)), instanceCount };
}

// Reads `["Key"] = "rbxassetid://123"` pairs from a previously generated module.
export function parseExistingImages(luau: string): Record<string, string> {
  const out: Record<string, string> = {};
  const re = /\["([^"]+)"\]\s*=\s*"(rbxassetid:\/\/\d+)"/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(luau))) {
    if (m[2] !== "rbxassetid://0") out[m[1]] = m[2];
  }
  return out;
}

// "https://www.figma.com/design/KEY/Name?node-id=12-34" -> "12:34"
export function nodeIdFromFigmaUrl(url: string): string | null {
  const m = url.match(/[?&]node-id=([0-9]+)(?:-|:|%3A)([0-9]+)/i);
  return m ? `${m[1]}:${m[2]}` : null;
}

export function moduleNameFrom(name: string): string {
  const parts = name.replace(/\[(btn|img|skip|scroll)\]/gi, "").split(/[^A-Za-z0-9]+/).filter(Boolean);
  const n = parts.map(p => p[0].toUpperCase() + p.slice(1)).join("");
  if (!n) return "FigmaUI";
  return /^[0-9]/.test(n) ? "UI" + n : n;
}
