// Read-only inspection: document, selection, nodes, reactions; viewport focus/selection.
// @stability stable (upstream logic, unchanged by the split) - do not change behaviour without checking server.ts
// Phase 1 additions (@stability new): compact mode (depth/fields/maxNodes) and find_nodes.
import { compactNode, wantsCompact } from "../core/compact.js";
import { describeNode, describeSelection, setNote } from "../core/selection.js";

import { sendProgressUpdate } from "../core/progress.js";
import { filterFigmaNode } from "../core/serialize.js";
import { generateCommandId } from "../core/utils.js";


export async function getDocumentInfo() {
  await figma.currentPage.loadAsync();
  const page = figma.currentPage;
  return {
    name: page.name,
    id: page.id,
    type: page.type,
    children: page.children.map((node) => ({
      id: node.id,
      name: node.name,
      type: node.type,
    })),
    currentPage: {
      id: page.id,
      name: page.name,
      childCount: page.children.length,
    },
    pages: [
      {
        id: page.id,
        name: page.name,
        childCount: page.children.length,
      },
    ],
  };
}

// id/name/type/visible as before, plus path, note, size, text, childCount, image (additive)
export async function getSelection() {
  return describeSelection();
}

async function nodeOrThrow(nodeId) {
  if (!nodeId) throw new Error("Missing nodeId parameter");
  const node = await figma.getNodeByIdAsync(nodeId);
  if (!node) throw new Error(`Node not found: ${nodeId}`);
  return node;
}

export async function getNodeInfo(nodeId) {
  const node = await figma.getNodeByIdAsync(nodeId);

  if (!node) {
    throw new Error(`Node not found with ID: ${nodeId}`);
  }

  const response = await node.exportAsync({
    format: "JSON_REST_V1",
  });

  return filterFigmaNode(response.document);
}

export async function getNodesInfo(nodeIds) {
  try {
    // Load all nodes in parallel
    const nodes = await Promise.all(
      nodeIds.map((id) => figma.getNodeByIdAsync(id))
    );

    // Filter out any null values (nodes that weren't found)
    const validNodes = nodes.filter((node) => node !== null);

    // Export all valid nodes in parallel
    const responses = await Promise.all(
      validNodes.map(async (node) => {
        const response = await node.exportAsync({
          format: "JSON_REST_V1",
        });
        return {
          nodeId: node.id,
          document: filterFigmaNode(response.document),
        };
      })
    );

    return responses;
  } catch (error) {
    throw new Error(`Error getting nodes info: ${error.message}`);
  }
}

export async function getReactions(nodeIds) {
  try {
    const commandId = generateCommandId();
    sendProgressUpdate(
      commandId,
      "get_reactions",
      "started",
      0,
      nodeIds.length,
      0,
      `Starting deep search for reactions in ${nodeIds.length} nodes and their children`
    );

    // Function to find nodes with reactions from the node and all its children
    async function findNodesWithReactions(node, processedNodes = new Set(), depth = 0, results = []) {
      // Skip already processed nodes (prevent circular references)
      if (processedNodes.has(node.id)) {
        return results;
      }
      
      processedNodes.add(node.id);
      
      // Check if the current node has reactions
      let filteredReactions = [];
      if (node.reactions && node.reactions.length > 0) {
        // Filter out reactions with navigation === 'CHANGE_TO'
        filteredReactions = node.reactions.filter(r => {
          // Some reactions may have action or actions array
          if (r.action && r.action.navigation === 'CHANGE_TO') return false;
          if (Array.isArray(r.actions)) {
            // If any action in actions array is CHANGE_TO, exclude
            return !r.actions.some(a => a.navigation === 'CHANGE_TO');
          }
          return true;
        });
      }
      const hasFilteredReactions = filteredReactions.length > 0;
      
      // If the node has filtered reactions, add it to results and apply highlight effect
      if (hasFilteredReactions) {
        results.push({
          id: node.id,
          name: node.name,
          type: node.type,
          depth: depth,
          hasReactions: true,
          reactions: filteredReactions,
          path: getNodePath(node)
        });
        // Apply highlight effect (orange border)
        await highlightNodeWithAnimation(node);
      }
      
      // If node has children, recursively search them
      if (node.children) {
        for (const child of node.children) {
          await findNodesWithReactions(child, processedNodes, depth + 1, results);
        }
      }
      
      return results;
    }
    
    // Function to apply animated highlight effect to a node
    async function highlightNodeWithAnimation(node) {
      // Save original stroke properties
      const originalStrokeWeight = node.strokeWeight;
      const originalStrokes = node.strokes ? [...node.strokes] : [];
      
      try {
        // Apply orange border stroke
        node.strokeWeight = 4;
        node.strokes = [{
          type: 'SOLID',
          color: { r: 1, g: 0.5, b: 0 }, // Orange color
          opacity: 0.8
        }];
        
        // Set timeout for animation effect (restore to original after 1.5 seconds)
        setTimeout(() => {
          try {
            // Restore original stroke properties
            node.strokeWeight = originalStrokeWeight;
            node.strokes = originalStrokes;
          } catch (restoreError) {
            console.error(`Error restoring node stroke: ${restoreError.message}`);
          }
        }, 1500);
      } catch (highlightError) {
        console.error(`Error highlighting node: ${highlightError.message}`);
        // Continue even if highlighting fails
      }
    }
    
    // Get node hierarchy path as a string
    function getNodePath(node) {
      const path = [];
      let current = node;
      
      while (current && current.parent) {
        path.unshift(current.name);
        current = current.parent;
      }
      
      return path.join(' > ');
    }

    // Array to store all results
    let allResults = [];
    let processedCount = 0;
    const totalCount = nodeIds.length;
    
    // Iterate through each node and its children to search for reactions
    for (let i = 0; i < nodeIds.length; i++) {
      try {
        const nodeId = nodeIds[i];
        const node = await figma.getNodeByIdAsync(nodeId);
        
        if (!node) {
          processedCount++;
          sendProgressUpdate(
            commandId,
            "get_reactions",
            "in_progress",
            processedCount / totalCount,
            totalCount,
            processedCount,
            `Node not found: ${nodeId}`
          );
          continue;
        }
        
        // Search for reactions in the node and its children
        const processedNodes = new Set();
        const nodeResults = await findNodesWithReactions(node, processedNodes);
        
        // Add results
        allResults = allResults.concat(nodeResults);
        
        // Update progress
        processedCount++;
        sendProgressUpdate(
          commandId,
          "get_reactions",
          "in_progress",
          processedCount / totalCount,
          totalCount,
          processedCount,
          `Processed node ${processedCount}/${totalCount}, found ${nodeResults.length} nodes with reactions`
        );
      } catch (error) {
        processedCount++;
        sendProgressUpdate(
          commandId,
          "get_reactions",
          "in_progress",
          processedCount / totalCount,
          totalCount,
          processedCount,
          `Error processing node: ${error.message}`
        );
      }
    }

    // Completion update
    sendProgressUpdate(
      commandId,
      "get_reactions",
      "completed",
      1,
      totalCount,
      totalCount,
      `Completed deep search: found ${allResults.length} nodes with reactions.`
    );

    return {
      nodesCount: nodeIds.length,
      nodesWithReactions: allResults.length,
      nodes: allResults
    };
  } catch (error) {
    throw new Error(`Failed to get reactions: ${error.message}`);
  }
}

export async function readMyDesign() {
  try {
    // Load all selected nodes in parallel
    const nodes = await Promise.all(
      figma.currentPage.selection.map((node) => figma.getNodeByIdAsync(node.id))
    );

    // Filter out any null values (nodes that weren't found)
    const validNodes = nodes.filter((node) => node !== null);

    // Export all valid nodes in parallel
    const responses = await Promise.all(
      validNodes.map(async (node) => {
        const response = await node.exportAsync({
          format: "JSON_REST_V1",
        });
        return {
          nodeId: node.id,
          document: filterFigmaNode(response.document),
        };
      })
    );

    return responses;
  } catch (error) {
    throw new Error(`Error getting nodes info: ${error.message}`);
  }
}

// Set focus on a specific node
export async function setFocus(params) {
  if (!params || !params.nodeId) {
    throw new Error("Missing nodeId parameter");
  }

  const node = await figma.getNodeByIdAsync(params.nodeId);
  if (!node) {
    throw new Error(`Node with ID ${params.nodeId} not found`);
  }

  // Set selection to the node
  figma.currentPage.selection = [node];
  
  // Scroll and zoom to show the node in viewport
  figma.viewport.scrollAndZoomIntoView([node]);

  return {
    success: true,
    name: node.name,
    id: node.id,
    message: `Focused on node "${node.name}"`
  };
}

// Set selection to multiple nodes
export async function setSelections(params) {
  if (!params || !params.nodeIds || !Array.isArray(params.nodeIds)) {
    throw new Error("Missing or invalid nodeIds parameter");
  }

  if (params.nodeIds.length === 0) {
    throw new Error("nodeIds array cannot be empty");
  }

  // Get all valid nodes
  const nodes = [];
  const notFoundIds = [];
  
  for (const nodeId of params.nodeIds) {
    const node = await figma.getNodeByIdAsync(nodeId);
    if (node) {
      nodes.push(node);
    } else {
      notFoundIds.push(nodeId);
    }
  }

  if (nodes.length === 0) {
    throw new Error(`No valid nodes found for the provided IDs: ${params.nodeIds.join(', ')}`);
  }

  // Set selection to the nodes
  figma.currentPage.selection = nodes;
  
  // Scroll and zoom to show all nodes in viewport
  figma.viewport.scrollAndZoomIntoView(nodes);

  const selectedNodes = nodes.map(node => ({
    name: node.name,
    id: node.id
  }));

  return {
    success: true,
    count: nodes.length,
    selectedNodes: selectedNodes,
    notFoundIds: notFoundIds,
    message: `Selected ${nodes.length} nodes${notFoundIds.length > 0 ? ` (${notFoundIds.length} not found)` : ''}`
  };
}

// find_nodes: search by name / type / text under a root (default: current page).
// Returns describeNode() entries (id, name, type, path, size, note...) - no deep tree.
export async function findNodes(params) {
  const p = params || {};
  let root = figma.currentPage;
  if (p.rootId) {
    root = await nodeOrThrow(p.rootId);
    if (root.type === "PAGE" && root.loadAsync) await root.loadAsync();
  }
  if (!("findAll" in root)) throw new Error(`Node ${root.id} (${root.type}) has no children to search`);
  let types = p.type || p.types;
  if (typeof types === "string") types = [types];
  types = Array.isArray(types) && types.length ? types.map((t) => String(t).toUpperCase()) : null;
  const name = p.name ? String(p.name).toLowerCase() : null;
  const text = p.text ? String(p.text).toLowerCase() : null;
  if (text && !types) types = ["TEXT"];
  if (!name && !text && !types) throw new Error("find_nodes needs at least one of: name, type, text");
  const limit = Number.isFinite(p.limit) ? Math.max(1, p.limit) : 50;

  const match = (n) => {
    if (p.visibleOnly && n.visible === false) return false;
    if (name) {
      const nn = n.name.toLowerCase();
      if (p.exact ? nn !== name : !nn.includes(name)) return false;
    }
    if (text && !(n.type === "TEXT" && String(n.characters).toLowerCase().includes(text))) return false;
    return true;
  };
  const candidates = types && root.findAllWithCriteria ? root.findAllWithCriteria({ types }) : root.findAll((n) => !types || types.includes(n.type));
  const found = candidates.filter(match);
  return {
    root: { id: root.id, name: root.name, type: root.type },
    count: found.length,
    truncated: found.length > limit,
    nodes: found.slice(0, limit).map(describeNode),
  };
}

export const commands = {
  get_document_info: () => getDocumentInfo(),
  get_selection: () => getSelection(),
  get_node_info: async (params) => {
    if (!params || !params.nodeId) throw new Error("Missing nodeId parameter");
    if (wantsCompact(params)) return compactNode(await nodeOrThrow(params.nodeId), params);
    return getNodeInfo(params.nodeId);
  },
  get_nodes_info: async (params) => {
    if (!params || !Array.isArray(params.nodeIds)) throw new Error("Missing or invalid nodeIds parameter");
    if (wantsCompact(params)) {
      const nodes = await Promise.all(params.nodeIds.map((id) => figma.getNodeByIdAsync(id)));
      return nodes.map((n, i) => (n ? compactNode(n, params) : { id: params.nodeIds[i], error: "Node not found" }));
    }
    return getNodesInfo(params.nodeIds);
  },
  read_my_design: (params) => {
    if (wantsCompact(params)) return figma.currentPage.selection.map((n) => compactNode(n, params));
    return readMyDesign();
  },
  find_nodes: findNodes,
  get_reactions: (params) => {
    if (!params || !Array.isArray(params.nodeIds)) throw new Error("Missing or invalid nodeIds parameter");
    return getReactions(params.nodeIds);
  },
  set_focus: setFocus,
  // Notes: short human description stored on a node (also editable in the plugin's Selection panel)
  get_node_note: async (params) => describeNode(await nodeOrThrow(params && params.nodeId)),
  set_node_note: async (params) => {
    const node = await nodeOrThrow(params && params.nodeId);
    setNote(node, params.note);
    return describeNode(node);
  },
  set_selections: setSelections,
};
