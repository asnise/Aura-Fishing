// @stability new - native Figma Design Motion keyframes

import { customBase64Encode } from "../core/utils.js";

const properties = new Set([
  "OPACITY", "ROTATION", "SCALE_XY", "TRANSLATION_X", "TRANSLATION_Y",
]);
const easings = new Set([
  "LINEAR", "HOLD", "EASE_IN", "EASE_OUT", "EASE_IN_AND_OUT", "EASE_OUT_BACK",
]);

async function motionKeyframes({ nodeId, tracks, duration } = {}) {
  if (typeof nodeId !== "string" || !nodeId) throw new Error("Missing nodeId parameter");
  const node = await figma.getNodeByIdAsync(nodeId);
  if (!node) throw new Error(`Node not found: ${nodeId}`);
  if (typeof node.applyManualKeyframeTrack !== "function") {
    throw new Error("Motion API is unavailable for this node or Figma editor");
  }

  if (duration !== undefined && (!Number.isFinite(duration) || duration <= 0)) {
    throw new Error("Duration must be positive seconds");
  }
  if (tracks !== undefined && (!Array.isArray(tracks) || !tracks.length)) {
    throw new Error("Tracks must be a non-empty array");
  }
  if (tracks && (node.parent?.type === "PAGE" || node.parent?.type === "SECTION")) {
    throw new Error("Animate layers inside a frame");
  }

  const seen = new Set();
  let end = duration ?? 0;
  const updates = (tracks ?? []).map(({ property, keyframes }) => {
    if (!properties.has(property) || seen.has(property)) {
      throw new Error(`Unsupported or duplicate Motion property: ${property}`);
    }
    seen.add(property);
    if (!Array.isArray(keyframes) || !keyframes.length) {
      throw new Error(`Expected at least one keyframe for ${property}`);
    }
    let previousTime = -1;
    const keys = keyframes.map(({ time, value, easing }) => {
      if (!Number.isFinite(time) || time < 0 || time <= previousTime) {
        throw new Error(`Keyframe times for ${property} must be non-negative and increasing`);
      }
      if (!Number.isFinite(value) || (property === "OPACITY" && (value < 0 || value > 1))) {
        throw new Error(`Invalid keyframe value for ${property}: ${value}`);
      }
      if (easing !== undefined && !easings.has(easing)) {
        throw new Error(`Unsupported easing: ${easing}`);
      }
      previousTime = time;
      return {
        timelinePosition: time,
        value: property === "SCALE_XY"
          ? { type: "VECTOR", value: { x: value, y: value } }
          : { type: "FLOAT", value },
        ...(easing === undefined ? {} : { easing: { type: easing } }),
      };
    });
    end = Math.max(end, previousTime);
    return { property, keyframes: keys };
  });

  for (const { property, keyframes } of updates) {
    node.applyManualKeyframeTrack({ type: "PROPERTY", name: property }, { keyframes });
  }
  const timeline = node.timelines[0];
  if (timeline && end > timeline.duration) node.setTimelineDuration(timeline.id, end);
  if (duration !== undefined && !timeline) throw new Error("No Motion timeline found for this node");

  return { nodeId, tracks: node.manualKeyframeTracks, timelines: node.timelines };
}

async function exportMotionVideo({ nodeId } = {}) {
  if (typeof nodeId !== "string" || !nodeId) throw new Error("Missing nodeId parameter");
  const node = await figma.getNodeByIdAsync(nodeId);
  if (!node) throw new Error(`Node not found: ${nodeId}`);
  if (node.type !== "FRAME" || node.parent?.type !== "PAGE") {
    throw new Error("Video export requires a top-level frame");
  }
  const bytes = await node.exportAsync({
    format: "MP4",
    quality: "MEDIUM",
    fps: 24,
    constraint: { type: "WIDTH", value: 960 },
  });
  return { nodeId, mimeType: "video/mp4", videoData: customBase64Encode(bytes) };
}

export const commands = {
  motion_keyframes: motionKeyframes,
  export_motion_video: exportMotionVideo,
};
