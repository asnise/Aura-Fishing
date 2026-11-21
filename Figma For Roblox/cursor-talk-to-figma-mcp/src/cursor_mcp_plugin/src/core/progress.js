// Progress updates for long-running commands (forwarded by ui.html to the MCP server).
// @stability stable (core) - shared by many commands


// Helper function for progress updates
export async function sendProgressUpdate(
  commandId,
  commandType,
  status,
  progress,
  totalItems,
  processedItems,
  message,
  payload = null
) {
  const update = {
    type: "command_progress",
    commandId,
    commandType,
    status,
    progress,
    totalItems,
    processedItems,
    message,
    timestamp: Date.now(),
  };

  // Add optional chunk information if present
  if (payload) {
    if (
      payload.currentChunk !== undefined &&
      payload.totalChunks !== undefined
    ) {
      update.currentChunk = payload.currentChunk;
      update.totalChunks = payload.totalChunks;
      update.chunkSize = payload.chunkSize;
    }
    update.payload = payload;
  }

  // Send to UI
  figma.ui.postMessage(update);
  console.log(`Progress update: ${status} - ${progress}% - ${message}`);

  // Yield so the Figma plugin sandbox flushes postMessage to ui.html
  // before the next iteration begins
  await new Promise((resolve) => setTimeout(resolve, 0));

  return update;
}
