export function byId<T extends HTMLElement = HTMLElement>(id: string): T {
  const element = document.getElementById(id);
  if (!element) throw new Error(`Missing element #${id}`);
  return element as T;
}

export function element<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  className = "",
  label = "",
): HTMLElementTagNameMap[K] {
  const result = document.createElement(tag);
  result.className = className;
  result.textContent = label;
  return result;
}

export function button(label: string, action: () => void, className = ""): HTMLButtonElement {
  const result = element("button", className, label);
  result.type = "button";
  result.addEventListener("click", action);
  return result;
}

export function pressed(control: HTMLElement, value: boolean): void {
  control.setAttribute("aria-pressed", String(value));
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}
