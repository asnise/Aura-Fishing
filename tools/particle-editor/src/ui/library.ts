import type { Asset, Layer, Project } from "../model.js";
import { button, byId, element, pressed } from "./dom.js";

interface Actions {
  selectLayer: (id: string) => void;
  selectAsset: (id: string) => void;
  toggleLayer: (id: string) => void;
  renameLayer: (id: string) => void;
  texture: (asset: Asset) => string;
}

const kinds = { sprite: "Sprite", emitter: "Emitter", ribbon: "Ribbon" };

export class Library {
  private readonly layerList = byId("layer-list");
  private readonly assetList = byId("asset-list");
  private readonly layerCount = byId("layer-count");
  private readonly assetCount = byId("asset-count");

  constructor(private readonly actions: Actions) {
    byId("layers-tab").addEventListener("click", () => this.show("layers"));
    byId("assets-tab").addEventListener("click", () => this.show("assets"));
  }

  show(tab: "layers" | "assets"): void {
    const layers = tab === "layers";
    pressed(byId("layers-tab"), layers);
    pressed(byId("assets-tab"), !layers);
    byId("layers-panel").hidden = !layers;
    byId("assets-panel").hidden = layers;
  }

  update(project: Project, layerId: string | null, assetId: string | null): void {
    const focus = document.activeElement;
    const key = focus instanceof HTMLElement ? focus.dataset.libraryControl : undefined;
    const activeIndex = project.layers.findIndex((layer) => layer.id === layerId);
    const layers = project.layers.map((layer) => this.layerItem(layer, layer.id === layerId));
    this.layerList.replaceChildren(...(layers.length ? layers : [element("li", "library-empty", "No layers")]));
    this.layerCount.textContent = String(layers.length);
    byId<HTMLButtonElement>("raise-layer").disabled = activeIndex <= 0;
    byId<HTMLButtonElement>("lower-layer").disabled = activeIndex < 0 || activeIndex === layers.length - 1;
    byId<HTMLButtonElement>("duplicate-layer").disabled = activeIndex < 0;
    byId<HTMLButtonElement>("delete-layer").disabled = activeIndex < 0;
    this.updateAssets(project.assets, assetId);

    if (key) document.querySelector<HTMLElement>(`[data-library-control="${CSS.escape(key)}"]`)?.focus({ preventScroll: true });
  }

  updateAssets(assets: Asset[], assetId: string | null): void {
    const rows = assets.map((asset) => this.assetItem(asset, asset.id === assetId));
    this.assetList.replaceChildren(...(rows.length ? rows : [element("li", "library-empty", "No textures imported")]));
    this.assetCount.textContent = String(rows.length);
  }

  private details(name: string, subtitle: string): HTMLElement {
    const result = element("span", "item-details");
    result.append(element("span", "item-name", name), element("span", "item-subtitle", subtitle));
    return result;
  }

  private layerItem(layer: Layer, selected: boolean): HTMLElement {
    const row = element("li", "layer-row");
    row.dataset.kind = layer.kind;
    row.dataset.visible = String(layer.visible);
    row.dataset.selected = String(selected);

    const main = button("", () => this.actions.selectLayer(layer.id), "item-main");
    main.dataset.libraryControl = `layer:${layer.id}`;
    pressed(main, selected);
    main.title = layer.name;
    main.append(element("span", "kind-mark"), this.details(layer.name, `${kinds[layer.kind]} / Tier ${layer.tier}`));
    main.addEventListener("dblclick", () => this.actions.renameLayer(layer.id));

    const visibility = button(layer.visible ? "Hide" : "Show", () => this.actions.toggleLayer(layer.id), "visibility");
    visibility.dataset.libraryControl = `visibility:${layer.id}`;
    visibility.setAttribute("aria-label", `${visibility.textContent} ${layer.name}`);
    row.append(main, visibility);
    return row;
  }

  private assetItem(asset: Asset, selected: boolean): HTMLElement {
    const row = element("li", "asset-row");
    row.dataset.selected = String(selected);
    const main = button("", () => this.actions.selectAsset(asset.id), "item-main");
    main.dataset.libraryControl = `asset:${asset.id}`;
    main.title = asset.path;
    pressed(main, selected);

    const image = element("img", "asset-thumb");
    image.alt = "";
    image.loading = "lazy";
    image.src = this.actions.texture(asset);
    image.addEventListener("error", () => { image.hidden = true; });
    main.append(image, this.details(asset.name, asset.matte === "luma" ? "Luma matte" : "PNG alpha"));
    row.append(main);
    return row;
  }
}
