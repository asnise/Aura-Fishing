import type { Layer, Project } from "../model.js";
import { button, byId, clamp, element, pressed } from "./dom.js";

export class Timeline {
  private readonly content = byId("timeline-content");
  private readonly ruler = byId("ruler");
  private readonly tracks = byId("tracks");
  private readonly playhead = byId("playhead");
  private readonly rulerHead = element("span", "ruler-head");
  private readonly timeLabel = byId("playback-time");
  private readonly playButton = byId<HTMLButtonElement>("play");
  private readonly zoomMenu = byId<HTMLSelectElement>("timeline-zoom");
  private duration = 1;
  private time = 0;

  constructor(private readonly selectLayer: (id: string) => void, private readonly seek: (time: number) => void) {
    this.enableScrubbing(this.ruler);
    this.ruler.addEventListener("keydown", (event) => this.onKeyDown(event));
    this.zoomMenu.addEventListener("change", () => {
      this.content.style.width = `${Number(this.zoomMenu.value) * 100}%`;
      this.drawRuler();
      const scroll = byId("timeline-scroll");
      const playhead = this.playhead.offsetLeft;
      if (playhead > scroll.scrollLeft + scroll.clientWidth) {
        scroll.scrollLeft = playhead - scroll.clientWidth / 2;
      }
    });
    this.timeLabel.setAttribute("aria-live", "off");
    new ResizeObserver(() => this.drawRuler()).observe(this.ruler);
  }

  update(project: Project, selected: string | null, tier: number): void {
    this.duration = Math.max(0.001, project.duration);
    this.ruler.setAttribute("aria-valuemax", String(project.duration));
    this.tracks.replaceChildren(...project.layers.map((layer) => this.track(layer, selected, tier)));
    this.drawRuler();
    this.updateTime(this.time);
  }

  updateTime(time: number): void {
    this.time = clamp(time, 0, this.duration);
    const fraction = this.time / this.duration;
    const position = `calc(var(--track-label-width) + (100% - var(--track-label-width)) * ${fraction})`;
    this.playhead.style.left = position;
    this.rulerHead.style.left = `${fraction * 100}%`;
    const value = this.time.toFixed(2);
    this.ruler.setAttribute("aria-valuenow", value);
    this.ruler.setAttribute("aria-valuetext", `${value} seconds`);
    this.timeLabel.textContent = `${value} / ${this.duration.toFixed(2)} s`;
  }

  updatePlaying(playing: boolean): void {
    pressed(this.playButton, playing);
    this.playButton.textContent = playing ? "Pause" : "Play";
  }

  private drawRuler(): void {
    const roughStep = this.duration / Math.max(2, Math.floor(this.ruler.clientWidth / 78));
    const magnitude = 10 ** Math.floor(Math.log10(roughStep));
    const step = [1, 2, 5, 10].map((value) => value * magnitude).find((value) => value >= roughStep) ?? this.duration;
    const count = Math.floor(this.duration / step + 1e-9);
    const decimals = Math.max(0, -Math.floor(Math.log10(step)));
    const ticks: HTMLElement[] = [];
    for (let index = 0; index <= count; index++) {
      const time = index * step;
      if (index > 0 && this.duration - time < step / 2) break;
      const tick = element("span", "ruler-tick", `${time.toFixed(decimals)}s`);
      tick.style.left = `${time / this.duration * 100}%`;
      ticks.push(tick);
    }
    const endTime = Number(this.duration.toFixed(Math.max(2, decimals)));
    const last = element("span", "ruler-tick ruler-end", `${endTime}s`);
    last.style.left = "100%";
    this.ruler.replaceChildren(...ticks, last, this.rulerHead);
    this.content.style.setProperty("--tick-width", `${step / this.duration * 100}%`);
  }

  private track(layer: Layer, selected: string | null, tier: number): HTMLElement {
    const row = element("div", "timeline-row");
    row.dataset.selected = String(layer.id === selected);
    row.dataset.visible = String(layer.visible && layer.tier <= tier);
    row.dataset.kind = layer.kind;

    const label = button(layer.name, () => this.selectLayer(layer.id), "track-label");
    label.title = layer.name;
    pressed(label, layer.id === selected);

    const lane = element("div", "track-lane");
    const start = clamp(layer.timing.start / this.duration, 0, 1);
    const end = clamp((layer.timing.start + layer.timing.duration) / this.duration, start, 1);
    if (end > start) {
      const clip = button(layer.name, () => this.selectLayer(layer.id), "track-clip");
      clip.style.left = `${start * 100}%`;
      clip.style.width = `${(end - start) * 100}%`;
      clip.title = `${layer.name} (${layer.timing.start.toFixed(2)}–${(layer.timing.start + layer.timing.duration).toFixed(2)} s)`;
      lane.append(clip);
    }
    this.enableScrubbing(lane);
    row.append(label, lane);
    return row;
  }

  private enableScrubbing(target: HTMLElement): void {
    const scrub = (event: PointerEvent) => {
      const bounds = target.getBoundingClientRect();
      if (bounds.width > 0) this.seek(clamp((event.clientX - bounds.left) / bounds.width, 0, 1) * this.duration);
    };
    target.addEventListener("pointerdown", (event) => {
      if (event.button !== 0 || (event.target as Element).closest("button")) return;
      target.setPointerCapture(event.pointerId);
      scrub(event);
    });
    target.addEventListener("pointermove", (event) => {
      if (target.hasPointerCapture(event.pointerId)) scrub(event);
    });
  }

  private onKeyDown(event: KeyboardEvent): void {
    const step = event.shiftKey ? 0.25 : 1 / 30;
    const targets: Record<string, number> = {
      ArrowRight: this.time + step,
      ArrowUp: this.time + step,
      ArrowLeft: this.time - step,
      ArrowDown: this.time - step,
      Home: 0,
      End: this.duration,
    };
    if (!(event.key in targets)) return;
    event.preventDefault();
    event.stopPropagation();
    this.seek(targets[event.key]);
  }
}
