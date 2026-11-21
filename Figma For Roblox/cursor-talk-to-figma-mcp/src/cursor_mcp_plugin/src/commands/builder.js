// Aura Fishing fork: JSON design-system builder.
// @stability stable (fork) - used by docs/figma/*_spec.py and tools/art/*.py


// ===========================================================================
// Design-system builder (Aura Fishing fork) — lets an agent build tokens,
// text styles and whole node trees from JSON in one command, through the
// local relay (no Figma MCP quota).
// Commands: upsert_variables, upsert_text_styles, build_tree, set_fills_empty
// ===========================================================================

export const rbxRefs = {};
 // spec key -> node id (lives while the plugin is open)

export function bHex(h) {
  h = String(h).replace("#", "");
  return { r: parseInt(h.slice(0, 2), 16) / 255, g: parseInt(h.slice(2, 4), 16) / 255, b: parseInt(h.slice(4, 6), 16) / 255 };
}

export async function bLocalVarsByName() {
  var vars = await figma.variables.getLocalVariablesAsync();
  var map = {};
  for (var i = 0; i < vars.length; i++) map[vars[i].name] = vars[i];
  return map;
}

export async function upsertVariables(params) {
  var cols = await figma.variables.getLocalVariableCollectionsAsync();
  var out = { created: 0, updated: 0, collections: [] };
  for (var c = 0; c < params.collections.length; c++) {
    var spec = params.collections[c];
    var col = null;
    for (var i = 0; i < cols.length; i++) if (cols[i].name === spec.name) col = cols[i];
    if (!col) {
      col = figma.variables.createVariableCollection(spec.name);
      col.renameMode(col.modes[0].modeId, spec.mode || "Default");
    }
    var modeId = col.modes[0].modeId;
    var existing = {};
    var all = await figma.variables.getLocalVariablesAsync();
    for (var j = 0; j < all.length; j++) if (all[j].variableCollectionId === col.id) existing[all[j].name] = all[j];
    for (var k = 0; k < spec.vars.length; k++) {
      var v = spec.vars[k];
      var variable = existing[v.name];
      if (!variable) { variable = figma.variables.createVariable(v.name, col, v.type); out.created++; } else { out.updated++; }
      variable.setValueForMode(modeId, v.type === "COLOR" ? bHex(v.value) : v.value);
      if (v.scopes) variable.scopes = v.scopes;
      if (v.description) variable.description = v.description;
    }
    out.collections.push({ name: col.name, id: col.id });
  }
  return out;
}

export async function upsertTextStyles(params) {
  var styles = await figma.getLocalTextStylesAsync();
  var byName = {};
  for (var i = 0; i < styles.length; i++) byName[styles[i].name] = styles[i];
  var ids = {};
  for (var s = 0; s < params.styles.length; s++) {
    var spec = params.styles[s];
    await figma.loadFontAsync({ family: spec.family, style: spec.style });
    var st = byName[spec.name] || figma.createTextStyle();
    st.name = spec.name;
    st.fontName = { family: spec.family, style: spec.style };
    st.fontSize = spec.size;
    if (spec.lineHeight) st.lineHeight = { unit: "PERCENT", value: spec.lineHeight };
    if (spec.letterSpacing) st.letterSpacing = { unit: "PERCENT", value: spec.letterSpacing };
    if (spec.description) st.description = spec.description;
    ids[spec.name] = st.id;
  }
  return { ids: ids };
}

export function bCollectFonts(spec, set, styleFonts) {
  if (spec.type === "TEXT") {
    if (spec.font) set[spec.font.family + "|" + spec.font.style] = spec.font;
    if (spec.textStyle && styleFonts[spec.textStyle]) { var f = styleFonts[spec.textStyle]; set[f.family + "|" + f.style] = f; }
    if (!spec.font && !spec.textStyle) set["Inter|Regular"] = { family: "Inter", style: "Regular" };
  }
  if (spec.children) for (var i = 0; i < spec.children.length; i++) bCollectFonts(spec.children[i], set, styleFonts);
}

export function bPaint(p, vars) {
  if (p === null || p === undefined) return null;
  if (typeof p === "string") return { type: "SOLID", color: bHex(p) };
  if (p.var) {
    var v = vars[p.var];
    if (!v) throw new Error("Unknown variable " + p.var);
    var bound = figma.variables.setBoundVariableForPaint({ type: "SOLID", color: { r: 0, g: 0, b: 0 } }, "color", v);
    if (p.opacity !== undefined) bound = Object.assign({}, bound, { opacity: p.opacity });
    return bound;
  }
  if (p.hex) return { type: "SOLID", color: bHex(p.hex), opacity: p.opacity === undefined ? 1 : p.opacity };
  if (p.grad) {
    var down = p.angle === 90;
    var stops = [];
    for (var i = 0; i < p.grad.length; i++) {
      var c = bHex(p.grad[i]);
      stops.push({ position: p.grad.length === 1 ? 0 : i / (p.grad.length - 1), color: { r: c.r, g: c.g, b: c.b, a: 1 } });
    }
    return { type: "GRADIENT_LINEAR", gradientTransform: down ? [[0, 1, 0], [-1, 0, 1]] : [[1, 0, 0], [0, 1, 0]], gradientStops: stops };
  }
  throw new Error("Bad paint " + JSON.stringify(p));
}

export function bPaints(p, vars) {
  if (p === null) return [];
  if (Array.isArray(p)) { var out = []; for (var i = 0; i < p.length; i++) out.push(bPaint(p[i], vars)); return out; }
  return [bPaint(p, vars)];
}

export function bEffects(list) {
  var out = [];
  for (var i = 0; i < list.length; i++) {
    var e = list[i];
    var c = bHex(e.color || "000000");
    out.push({ type: e.inner ? "INNER_SHADOW" : "DROP_SHADOW", color: { r: c.r, g: c.g, b: c.b, a: e.a === undefined ? 0.25 : e.a }, offset: { x: e.x || 0, y: e.y || 0 }, radius: e.blur || 0, spread: e.spread || 0, visible: true, blendMode: "NORMAL" });
  }
  return out;
}

export function bApplyCommon(node, spec, vars, isPatch) {
  if (spec.name) node.name = spec.name;
  if ("fills" in node) {
    if (spec.fill !== undefined) node.fills = bPaints(spec.fill, vars);
    else if (!isPatch && spec.type !== "TEXT" && spec.type !== "SVG" && spec.type !== "INSTANCE") node.fills = [];
  }
  if (spec.stroke !== undefined && "strokes" in node) {
    node.strokes = bPaints(spec.stroke, vars);
    if (spec.strokeW !== undefined) node.strokeWeight = spec.strokeW;
    if (spec.strokeAlign) node.strokeAlign = spec.strokeAlign;
    if (spec.strokeSides) {
      node.strokeTopWeight = spec.strokeSides.t || 0; node.strokeRightWeight = spec.strokeSides.r || 0;
      node.strokeBottomWeight = spec.strokeSides.b || 0; node.strokeLeftWeight = spec.strokeSides.l || 0;
    }
  }
  if (spec.radius !== undefined && "cornerRadius" in node) node.cornerRadius = spec.radius;
  if (spec.radiusVar && vars[spec.radiusVar] && "cornerRadius" in node) {
    var rv = vars[spec.radiusVar];
    node.setBoundVariable("topLeftRadius", rv); node.setBoundVariable("topRightRadius", rv);
    node.setBoundVariable("bottomLeftRadius", rv); node.setBoundVariable("bottomRightRadius", rv);
  }
  if (spec.effects && "effects" in node) node.effects = bEffects(spec.effects);
  if (spec.opacity !== undefined) node.opacity = spec.opacity;
  if (spec.clip !== undefined && "clipsContent" in node) node.clipsContent = spec.clip;
  if (spec.visible === false) node.visible = false;
}

export function bSetupLayout(node, spec, vars) {
  if (!spec.layout) return;
  var horiz = spec.layout === "H";
  node.layoutMode = horiz ? "HORIZONTAL" : "VERTICAL";
  node.primaryAxisSizingMode = (horiz ? spec.w : spec.h) ? "FIXED" : "AUTO";
  node.counterAxisSizingMode = (horiz ? spec.h : spec.w) ? "FIXED" : "AUTO";
  if (spec.gap !== undefined) node.itemSpacing = spec.gap;
  if (spec.gapVar && vars[spec.gapVar]) node.setBoundVariable("itemSpacing", vars[spec.gapVar]);
  if (spec.wrap) { node.layoutWrap = "WRAP"; if (spec.rowGap !== undefined) node.counterAxisSpacing = spec.rowGap; }
  var p = spec.pad;
  if (p !== undefined) {
    if (typeof p === "number") p = [p, p, p, p];
    if (p.length === 2) p = [p[0], p[1], p[0], p[1]];
    node.paddingTop = p[0]; node.paddingRight = p[1]; node.paddingBottom = p[2]; node.paddingLeft = p[3];
  }
  if (spec.main) node.primaryAxisAlignItems = spec.main;
  if (spec.cross) node.counterAxisAlignItems = spec.cross;
}

export async function bBuild(spec, parent, vars, textStyles, created) {
  var node;
  var t = spec.type || "FRAME";
  if (t === "FRAME" || t === "COMPONENT" || t === "VARIANTS") {
    node = t === "COMPONENT" ? figma.createComponent() : figma.createFrame();
  } else if (t === "SECTION") {
    node = figma.createSection();
  } else if (t === "TEXT") {
    node = figma.createText();
  } else if (t === "RECT") {
    node = figma.createRectangle();
  } else if (t === "ELLIPSE") {
    node = figma.createEllipse();
  } else if (t === "SVG") {
    node = figma.createNodeFromSvg(spec.svg);
  } else if (t === "INSTANCE") {
    var compId = rbxRefs[spec.ref] || spec.ref;
    var comp = await figma.getNodeByIdAsync(compId);
    if (!comp) throw new Error("Unknown component ref " + spec.ref);
    if (comp.type === "COMPONENT_SET") comp = comp.defaultVariant;
    if (spec.variant && comp.parent && comp.parent.type === "COMPONENT_SET") {
      var found = comp.parent.findChild(function (c) { return c.name === spec.variant; });
      if (found) comp = found;
    }
    node = comp.createInstance();
  } else {
    throw new Error("Unknown node type " + t);
  }
  parent.appendChild(node);
  if (t !== "INSTANCE") bApplyCommon(node, spec, vars, false);
  else {
    if (spec.name) node.name = spec.name;
    if (spec.fill !== undefined) node.fills = bPaints(spec.fill, vars);
    if (spec.hide) {
      for (var hi = 0; hi < spec.hide.length; hi++) {
        var hn = node.findOne(function (n) { return n.name === spec.hide[hi]; });
        if (hn) hn.visible = false;
      }
    }
    if (spec.texts) {
      for (var tk in spec.texts) {
        var tn = node.findOne(function (n) { return n.type === "TEXT" && n.name === tk; });
        if (tn) {
          if (tn.fontName !== figma.mixed) await figma.loadFontAsync(tn.fontName);
          tn.characters = String(spec.texts[tk]);
        }
      }
    }
  }

  if (t === "TEXT") {
    if (spec.textStyle) {
      var st = textStyles[spec.textStyle];
      if (!st) throw new Error("Unknown text style " + spec.textStyle);
      await node.setTextStyleIdAsync(st.id);
    } else {
      node.fontName = spec.font || { family: "Inter", style: "Regular" };
      if (spec.size) node.fontSize = spec.size;
    }
    node.characters = String(spec.text === undefined ? "" : spec.text);
    node.fills = bPaints(spec.color === undefined ? "000000" : spec.color, vars);
    if (spec.align) node.textAlignHorizontal = spec.align;
    if (spec.valign) node.textAlignVertical = spec.valign;
    if (spec.textStroke) { node.strokes = bPaints(spec.textStroke, vars); node.strokeWeight = spec.textStrokeW || 2; node.strokeAlign = "OUTSIDE"; }
    if (spec.w) { node.resize(spec.w, node.height); node.textAutoResize = "HEIGHT"; }
  }

  if (t === "FRAME" || t === "COMPONENT" || t === "VARIANTS") {
    if (spec.w || spec.h) node.resize(spec.w || 100, spec.h || 100);
    bSetupLayout(node, spec, vars);
    if (spec.children) {
      for (var i = 0; i < spec.children.length; i++) await bBuild(spec.children[i], node, vars, textStyles, created);
    }
    if (spec.layout) {
      // fixed sizes after children: FIXED axes keep w/h
      if (spec.w) { if (spec.layout === "H") node.primaryAxisSizingMode = "FIXED"; else node.counterAxisSizingMode = "FIXED"; node.resize(spec.w, node.height); }
      if (spec.h) { if (spec.layout === "V") node.primaryAxisSizingMode = "FIXED"; else node.counterAxisSizingMode = "FIXED"; node.resize(node.width, spec.h); }
    }
    if (t === "COMPONENT" && spec.description) node.description = spec.description;
  } else if (t === "SECTION") {
    if (spec.children) {
      for (var si = 0; si < spec.children.length; si++) await bBuild(spec.children[si], node, vars, textStyles, created);
    }
    var sw = spec.w, sh = spec.h;
    if (!sw || !sh) {
      var mx = 0, my = 0;
      for (var sc = 0; sc < node.children.length; sc++) {
        var ch2 = node.children[sc];
        mx = Math.max(mx, ch2.x + ch2.width); my = Math.max(my, ch2.y + ch2.height);
      }
      sw = sw || mx + (spec.pad || 80); sh = sh || my + (spec.pad || 80);
    }
    node.resizeWithoutConstraints(sw, sh);
    if (spec.fill === undefined) node.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
  } else if ((t === "RECT" || t === "ELLIPSE" || t === "SVG") && (spec.w || spec.h)) {
    node.resize(spec.w || node.width, spec.h || node.height);
  }

  // sizing inside auto-layout parent
  if (parent.layoutMode && parent.layoutMode !== "NONE") {
    if (spec.fillW) node.layoutSizingHorizontal = "FILL";
    if (spec.fillH) node.layoutSizingVertical = "FILL";
    if (spec.absolute) { node.layoutPositioning = "ABSOLUTE"; }
  }
  if (spec.x !== undefined && (!parent.layoutMode || parent.layoutMode === "NONE" || spec.absolute)) node.x = spec.x;
  if (spec.y !== undefined && (!parent.layoutMode || parent.layoutMode === "NONE" || spec.absolute)) node.y = spec.y;

  if (t === "VARIANTS") {
    var comps = node.children.filter(function (c) { return c.type === "COMPONENT"; });
    var set = figma.combineAsVariants(comps, parent);
    set.name = spec.name || "Variants";
    bSetupLayout(set, { layout: spec.layout || "H", gap: spec.gap === undefined ? 16 : spec.gap, pad: spec.pad === undefined ? 16 : spec.pad, wrap: spec.wrap, rowGap: spec.rowGap }, vars);
    if (spec.setFill !== undefined) set.fills = bPaints(spec.setFill, vars);
    if (spec.setRadius !== undefined) set.cornerRadius = spec.setRadius;
    if (spec.description) set.description = spec.description;
    node.remove();
    node = set;
  }

  if (spec.key) rbxRefs[spec.key] = node.id;
  created.push(node.id);
  return node;
}

export async function buildTree(params) {
  if (params.pageId) {
    var page = await figma.getNodeByIdAsync(params.pageId);
    if (page && page.type === "PAGE") await figma.setCurrentPageAsync(page);
  }
  var vars = await bLocalVarsByName();
  var tsList = await figma.getLocalTextStylesAsync();
  var textStyles = {};
  var styleFonts = {};
  for (var i = 0; i < tsList.length; i++) { textStyles[tsList[i].name] = tsList[i]; styleFonts[tsList[i].name] = tsList[i].fontName; }
  var fonts = {};
  bCollectFonts(params.tree, fonts, styleFonts);
  var keys = Object.keys(fonts);
  for (var f = 0; f < keys.length; f++) await figma.loadFontAsync(fonts[keys[f]]);

  var parent = params.parentId ? await figma.getNodeByIdAsync(params.parentId) : figma.currentPage;
  var insertIndex = -1;
  if (params.replaceId) {
    // replace one specific node in place (same parent, same z-order / auto-layout position)
    var target = await figma.getNodeByIdAsync(params.replaceId);
    if (!target) throw new Error("replaceId not found " + params.replaceId);
    parent = target.parent;
    insertIndex = parent.children.indexOf(target);
    target.remove();
  }
  if (!parent) throw new Error("Parent not found " + params.parentId);
  if (params.replaceName) {
    var old = parent.findChild ? parent.findChild(function (n) { return n.name === params.replaceName; }) : null;
    if (old) { insertIndex = parent.children.indexOf(old); old.remove(); }
  }
  var created = [];
  var root = await bBuild(params.tree, parent, vars, textStyles, created);
  if (insertIndex >= 0 && "insertChild" in parent) {
    var keepX = root.x, keepY = root.y;
    parent.insertChild(Math.min(insertIndex, parent.children.length - 1), root);
    if (!parent.layoutMode || parent.layoutMode === "NONE") { root.x = keepX; root.y = keepY; }
  }
  if (!params.parentId && params.tree.x === undefined) {
    var maxX = 0;
    for (var c = 0; c < figma.currentPage.children.length; c++) {
      var ch = figma.currentPage.children[c];
      if (ch.id !== root.id) maxX = Math.max(maxX, ch.x + ch.width);
    }
    root.x = maxX + 200; root.y = 0;
  }
  var refs = {};
  for (var k in rbxRefs) refs[k] = rbxRefs[k];
  return { rootId: root.id, count: created.length, refs: refs, bounds: { x: root.x, y: root.y, w: root.width, h: root.height } };
}

export async function setFillsEmpty(params) {
  var out = [];
  for (var i = 0; i < params.nodeIds.length; i++) {
    var n = await figma.getNodeByIdAsync(params.nodeIds[i]);
    if (n && "fills" in n) { n.fills = []; out.push(n.id); }
  }
  if (params.queryRootId && params.names) {
    var root = await figma.getNodeByIdAsync(params.queryRootId);
    if (root) {
      var hits = root.findAll(function (n) { return params.names.indexOf(n.name) >= 0 && n.type === "FRAME"; });
      for (var j = 0; j < hits.length; j++) { hits[j].fills = []; out.push(hits[j].id); }
    }
  }
  return { cleared: out };
}

export async function patchNodes(params) {
  var out = [];
  for (var i = 0; i < params.patches.length; i++) {
    var p = params.patches[i];
    var n = await figma.getNodeByIdAsync(p.id);
    if (!n) continue;
    var vars = await bLocalVarsByName();
    bApplyCommon(n, p, vars, true);
    // ranges: [{ match: "2,340 coins", fill: "#C98B1E" | {var}, font: { family, style } }] — style part of a TEXT node
    if (p.ranges && n.type === "TEXT") {
      for (var r = 0; r < p.ranges.length; r++) {
        var rg = p.ranges[r];
        var start = n.characters.indexOf(rg.match);
        if (start < 0) continue;
        var end = start + rg.match.length;
        var segs = n.getRangeAllFontNames(0, n.characters.length);
        for (var s = 0; s < segs.length; s++) await figma.loadFontAsync(segs[s]);
        if (rg.font) {
          await figma.loadFontAsync(rg.font);
          n.setRangeFontName(start, end, rg.font);
        }
        if (rg.fill !== undefined) n.setRangeFills(start, end, bPaints(rg.fill, vars));
      }
    }
    if (p.remove) n.remove();
    out.push(p.id);
  }
  return { patched: out };
}

export const commands = {
  upsert_variables: upsertVariables,
  upsert_text_styles: upsertTextStyles,
  build_tree: buildTree,
  set_fills_empty: setFillsEmpty,
  patch_nodes: patchNodes,
};
