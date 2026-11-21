// Messages UI iframe -> plugin main thread (src/main.js)
export function postToPlugin(pluginMessage) {
  parent.postMessage({ pluginMessage }, "*");
}
