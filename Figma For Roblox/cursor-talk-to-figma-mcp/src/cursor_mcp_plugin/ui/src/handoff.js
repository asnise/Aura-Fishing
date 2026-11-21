const workflows = {
  inspect: "Use get_selection, then get_node_info with a small depth on the node IDs below. Summarize the relevant structure and return exact node IDs.",
  motion: "Use get_nodes_info for source layers and motion_keyframes to read or update named tracks. Keep keyframes editable. Verify the timeline and run export_motion_video through the local CLI for a rendered check.",
  roblox: "Inspect the named Figma nodes first. Reuse existing Aura Fishing UI components and assets in Roblox. Run the Luau type check and verify the affected flow in Studio.",
};

export function formatHandoff({ channel, selection, mode, task = "", done = "" }) {
  const { page, selection: nodes, selectionCount, truncated } = selection;
  const references = nodes.map((node) =>
    `- ${node.name} (${node.id}), ${node.type}${node.path ? ` in ${node.path}` : ""}${node.note ? ` — ${node.note}` : ""}`);
  if (truncated) references.push(`- ${selectionCount - nodes.length} additional selected nodes. Run get_selection for context.`);
  const starter = !nodes.length ? "get_selection({})" : mode === "motion"
    ? `motion_keyframes(${JSON.stringify({ nodeId: nodes[0].id })})`
    : `get_nodes_info(${JSON.stringify({ nodeIds: nodes.map((node) => node.id) })})`;
  return [
    "Aura Fishing agent handoff",
    `Connect to local Figma MCP on channel ${channel}.`,
    page ? `Figma page: ${page.name} (${page.id})` : "Figma page: inspect the active page.",
    "References", ...(references.length ? references : ["No layers selected. Use the references in the task."]),
    "Task", task.trim() || "Confirm the intended change before editing.",
    "Workflow", workflows[mode] || workflows.inspect,
    `First MCP call: ${starter}`,
    ...(done.trim() ? ["Constraints and success criteria", done.trim()] : []),
    "Report the resulting node IDs or files, verification performed, and unresolved issues.",
  ].join("\n");
}
