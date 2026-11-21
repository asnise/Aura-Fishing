// Element lookups (the script is inlined at the end of <body>, so the DOM exists).
const $ = (id) => document.getElementById(id);

export const portInput = $("port");
export const connectButton = $("btn-connect");
export const connectionStatus = $("connection-status");

export const tabs = document.querySelectorAll(".tab");
export const tabContents = document.querySelectorAll(".tab-content");

export const progressContainer = $("progress-container");
export const progressBar = $("progress-bar");
export const progressMessage = $("progress-message");
export const progressStatus = $("progress-status");
export const progressPercentage = $("progress-percentage");

export const mcpConfigSection = $("mcp-config");
export const mcpJson = $("mcp-json");
export const copyButton = $("btn-copy");

export const selCount = $("sel-count");
export const selList = $("sel-list");
export const copyIdsButton = $("btn-copy-ids");
