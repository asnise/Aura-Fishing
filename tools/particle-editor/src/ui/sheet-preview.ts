import type { Asset, Layer, Rect } from "../model.js";
import { frameIndex, frameRect } from "../render/atlas.js";
import { button, clamp, element } from "./dom.js";

type Fit = { x: number; y: number; scale: number };

export class SheetPreview {
  readonly section = element("section", "inspector-section");
  private readonly atlasCanvas = element("canvas");
  private readonly frameCanvas = element("canvas");
  private readonly details = element("span", "sheet-message");
  private readonly frameNumber = element("input");
  private readonly follow = element("input");
  private readonly exportButton = button("Export frame PNG", () => this.exportFrame(), "sheet-export");
  private readonly image = new Image();
  private inspectedFrame = 0;
  private drawnIndex = -1;
  private current: Rect | null = null;
  private atlasFit: Fit | null = null;
  private time = 0;
  private imageError = false;

  constructor(private readonly layer: () => Layer, private readonly asset: Asset, url: string) {
    const views = element("div", "sheet-views");
    views.append(this.canvasView("Source sheet", this.atlasCanvas), this.canvasView("Frame preview", this.frameCanvas));
    this.atlasCanvas.title = "Click a cell to inspect it";
    this.atlasCanvas.addEventListener("click", (event) => this.pickCell(event));

    this.follow.type = "checkbox";
    this.follow.checked = true;
    this.follow.addEventListener("change", () => {
      this.inspectedFrame = Math.max(0, this.drawnIndex);
      this.update(this.time, true);
    });
    this.frameNumber.type = "number";
    this.frameNumber.step = "1";
    this.frameNumber.min = "1";
    this.frameNumber.value = "1";
    this.frameNumber.addEventListener("change", () => {
      this.inspectedFrame = Math.max(0, Math.floor(this.frameNumber.valueAsNumber || 1) - 1);
      this.update(this.time, true);
    });
    this.exportButton.disabled = true;
    this.details.textContent = "Loading PNG";
    this.details.setAttribute("role", "status");
    this.section.append(
      element("h3", "", "Frame preview"),
      views,
      this.details,
      this.field("Follow playhead", this.follow),
      this.field("Inspect frame", this.frameNumber),
      this.exportButton,
    );

    this.image.addEventListener("load", () => this.update(this.time, true));
    this.image.addEventListener("error", () => {
      this.imageError = true;
      this.update(this.time, true);
    });
    this.image.src = url;
  }

  get dimensions(): [number, number] | null {
    return this.image.naturalWidth ? [this.image.naturalWidth, this.image.naturalHeight] : null;
  }

  update(time: number, force = false): void {
    this.time = time;
    if (!this.section.isConnected) return;
    const { sheet, timing } = this.layer();
    const count = sheet.columns * sheet.rows;
    const localTime = Math.max(0, time - timing.start) * timing.speed + timing.offset;
    const index = this.follow.checked ? frameIndex(sheet, localTime) : clamp(this.inspectedFrame, 0, count - 1);
    const size = this.dimensions;
    this.frameNumber.disabled = this.follow.checked || !size;
    this.frameNumber.max = String(count);
    if (!force && this.drawnIndex === index && this.frameCanvas.clientWidth === this.frameCanvas.width) return;
    if (document.activeElement !== this.frameNumber || force) this.frameNumber.value = String(index + 1);
    if (this.imageError) {
      this.details.textContent = `Could not open ${this.asset.name}. Check the PNG path in Assets.`;
      return;
    }
    if (!size) return;

    this.drawnIndex = index;
    const [width, height] = size;
    this.current = frameRect(sheet, width, height, index);
    this.exportButton.disabled = this.current === null;
    this.paintAtlas(width, height);
    const frameContext = this.clear(this.frameCanvas);
    if (!this.current) {
      this.details.textContent = "No frame fits. Check the grid, region, margin, and gap.";
      return;
    }

    const { x, y, width: frameWidth, height: frameHeight } = this.current;
    const fit = this.fit(this.frameCanvas, frameWidth, frameHeight);
    frameContext?.drawImage(this.image, x, y, frameWidth, frameHeight, fit.x, fit.y, frameWidth * fit.scale, frameHeight * fit.scale);
    const details = `${width} × ${height} sheet / ${frameWidth} × ${frameHeight} frame`;
    if (this.details.textContent !== details) this.details.textContent = details;
  }

  private canvasView(label: string, canvas: HTMLCanvasElement): HTMLElement {
    const view = element("div", "sheet-view");
    const box = element("div", "sheet-box checker");
    canvas.setAttribute("aria-label", label);
    box.append(canvas);
    view.append(element("span", "", label), box);
    return view;
  }

  private field(label: string, input: HTMLInputElement): HTMLLabelElement {
    const field = element("label", "field");
    field.append(element("span", "", label), input);
    return field;
  }

  private clear(canvas: HTMLCanvasElement): CanvasRenderingContext2D | null {
    const width = Math.max(1, canvas.clientWidth);
    const height = Math.max(1, canvas.clientHeight);
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width;
      canvas.height = height;
    }
    const context = canvas.getContext("2d");
    context?.clearRect(0, 0, width, height);
    return context;
  }

  private fit(canvas: HTMLCanvasElement, width: number, height: number): Fit {
    const scale = Math.min(canvas.width / width, canvas.height / height);
    return { x: (canvas.width - width * scale) / 2, y: (canvas.height - height * scale) / 2, scale };
  }

  private paintAtlas(width: number, height: number): void {
    const context = this.clear(this.atlasCanvas);
    if (!context) return;
    const fit = this.fit(this.atlasCanvas, width, height);
    this.atlasFit = fit;
    context.drawImage(this.image, fit.x, fit.y, width * fit.scale, height * fit.scale);
    const { sheet } = this.layer();
    context.strokeStyle = "#dbeaf481";
    if (width * fit.scale / sheet.columns >= 4 && height * fit.scale / sheet.rows >= 4) {
      for (let index = 0; index < sheet.columns * sheet.rows; index++) {
        const cell = frameRect(sheet, width, height, index);
        if (cell) this.strokeCell(context, fit, cell);
      }
    }
    if (this.current) {
      context.strokeStyle = "#75ddc8";
      context.lineWidth = 2;
      this.strokeCell(context, fit, this.current);
      context.lineWidth = 1;
    }
  }

  private strokeCell(context: CanvasRenderingContext2D, fit: Fit, cell: Rect): void {
    context.strokeRect(fit.x + cell.x * fit.scale, fit.y + cell.y * fit.scale, cell.width * fit.scale, cell.height * fit.scale);
  }

  private pickCell(event: MouseEvent): void {
    if (!this.atlasFit || !this.dimensions) return;
    const { x, y, scale } = this.atlasFit;
    const px = (event.offsetX - x) / scale;
    const py = (event.offsetY - y) / scale;
    const { sheet } = this.layer();
    const [width, height] = this.dimensions;
    for (let index = 0; index < sheet.columns * sheet.rows; index++) {
      const cell = frameRect(sheet, width, height, index);
      if (cell && px >= cell.x && py >= cell.y && px < cell.x + cell.width && py < cell.y + cell.height) {
        this.inspectedFrame = index;
        this.follow.checked = false;
        this.update(this.time, true);
        return;
      }
    }
  }

  private exportFrame(): void {
    const frame = this.current;
    if (!frame) return;
    const index = this.drawnIndex;
    const exportCanvas = element("canvas");
    exportCanvas.width = frame.width;
    exportCanvas.height = frame.height;
    const context = exportCanvas.getContext("2d");
    if (!context) {
      this.details.textContent = "Could not create the frame PNG.";
      return;
    }
    try {
      context.drawImage(this.image, frame.x, frame.y, frame.width, frame.height, 0, 0, frame.width, frame.height);
      exportCanvas.toBlob((blob) => {
        if (!blob) {
          this.details.textContent = "Could not create the frame PNG.";
          return;
        }
        const download = element("a");
        const url = URL.createObjectURL(blob);
        download.href = url;
        download.download = `${this.asset.name.replace(/\.png$/i, "").replace(/[^\p{L}\p{N} _-]/gu, "_")}-${index + 1}.png`;
        download.click();
        window.setTimeout(() => URL.revokeObjectURL(url), 1000);
      }, "image/png");
    } catch {
      this.details.textContent = "Could not create the frame PNG.";
    }
  }
}
