// Plugin runtime state + persisted settings (figma.clientStorage).
// @stability stable (core) - shared by many commands
export const state = {
  serverPort: 3055, // Default port
};

// Update plugin settings
export function updateSettings(settings) {
  if (settings.serverPort) {
    state.serverPort = settings.serverPort;
  }

  figma.clientStorage.setAsync("settings", {
    serverPort: state.serverPort,
  });
}

// Load saved settings and push them to the UI (called once at boot)
export async function loadSettings() {
  try {
    const savedSettings = await figma.clientStorage.getAsync("settings");
    if (savedSettings && savedSettings.serverPort) {
      state.serverPort = savedSettings.serverPort;
    }
    figma.ui.postMessage({
      type: "init-settings",
      settings: { serverPort: state.serverPort },
    });
  } catch (error) {
    console.error("Error loading settings:", error);
  }
}
