// Aura Fishing fork: one-off maintenance scripts tied to specific node ids.
// @stability one-off - delete when no longer needed
// Safe to delete once the job is done. Keep new one-offs here, not in the
// general-purpose modules.

const TINTED_BOARD_ID = "3539:27990";

// Removes the "Tinted" layer from every "Vec <name>" cell on the icon board,
// shrinks the cell to 88px and returns the tile icon as PNG (base64, 1.6x).
async function removeTintedAndExport() {
  const board = await figma.getNodeByIdAsync(TINTED_BOARD_ID);
  if (!board) throw new Error(`Board ${TINTED_BOARD_ID} not found`);
  const body = board.children.find((c) => c.name === "Body");
  if (!body) throw new Error(`Body not found in ${TINTED_BOARD_ID}`);

  const exports = [];
  for (const row of body.children) {
    if (!row.children) continue;
    for (const cell of row.children) {
      if (!cell.name.startsWith("Vec ")) continue;
      const keyName = cell.name.replace("Vec ", "");
      const tile = cell.children && cell.children.find((c) => c.name === "Tile");
      const tinted = cell.children && cell.children.find((c) => c.name === "Tinted");

      if (tinted) tinted.remove();
      if ("resize" in cell) cell.resize(cell.width, 88);

      if (tile && tile.children && tile.children.length > 0) {
        const tIcon = tile.children[0];
        const bytes = await tIcon.exportAsync({
          format: "PNG",
          constraint: { type: "SCALE", value: 1.6 },
        });
        exports.push({ key: keyName, id: tIcon.id, base64: figma.base64Encode(bytes) });
      }
    }
  }
  return { exported: exports };
}

export const commands = {
  remove_tinted_and_export: removeTintedAndExport,
};
