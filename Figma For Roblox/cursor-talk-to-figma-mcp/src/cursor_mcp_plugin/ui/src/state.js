import { DEFAULT_PORT } from "./config.js";

// WebSocket connection state (UI iframe side)
export const state = {
  connected: false,
  socket: null,
  serverPort: DEFAULT_PORT,
  pendingRequests: new Map(),
  channel: null,
  activeRequestId: null,
};
