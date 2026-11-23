import type { Camera } from '../model.js';

export type Point = { x: number; y: number; depth: number; scale: number };
export type Projection = (x: number, y: number, z: number) => Point;
export type DrawItem = { depth: number; draw: () => void };

const CAMERA_DISTANCE = 11;
const TARGET_HEIGHT = 2.3;
const GRID_RADIUS = 2.6;

export function createProjection(width: number, height: number, camera: Camera): Projection {
  const cosYaw = Math.cos(camera.yaw);
  const sinYaw = Math.sin(camera.yaw);
  const cosPitch = Math.cos(camera.pitch);
  const sinPitch = Math.sin(camera.pitch);
  const perspective = (depth: number) => CAMERA_DISTANCE / Math.max(1, CAMERA_DISTANCE - depth);
  const vertical = (forward: number, up: number) => (forward * sinPitch - up * cosPitch)
    * perspective(forward * cosPitch + up * sinPitch);
  const head = Math.min(vertical(-.62, 2.38), vertical(.62, 2.38));
  const floor = Math.max(vertical(-GRID_RADIUS, -TARGET_HEIGHT), vertical(GRID_RADIUS, -TARGET_HEIGHT));
  const fittedScale = Math.min(width / 6.4, height * .88 / Math.max(3.5, floor - head));
  const center = (height - (head + floor) * fittedScale) / 2;
  return (x, y, z) => {
    const horizontal = x * cosYaw - z * sinYaw;
    const forward = x * sinYaw + z * cosYaw;
    const up = y - TARGET_HEIGHT;
    const depth = forward * cosPitch + up * sinPitch;
    const scale = fittedScale * camera.zoom * perspective(depth);
    return { x: width / 2 + horizontal * scale, y: center + (forward * sinPitch - up * cosPitch) * scale, depth, scale };
  };
}

export function drawGrid(context: CanvasRenderingContext2D, project: Projection): void {
  context.beginPath();
  for (let mark = -4; mark <= 4; mark++) {
    const offset = mark * GRID_RADIUS / 4;
    const near = project(offset, 0, -GRID_RADIUS);
    const far = project(offset, 0, GRID_RADIUS);
    const left = project(-GRID_RADIUS, 0, offset);
    const right = project(GRID_RADIUS, 0, offset);
    context.moveTo(near.x, near.y);
    context.lineTo(far.x, far.y);
    context.moveTo(left.x, left.y);
    context.lineTo(right.x, right.y);
  }
  context.strokeStyle = 'rgba(163, 207, 209, .17)';
  context.lineWidth = 1;
  context.stroke();
}

// Centers, dimensions, and shades of the existing Aura Fishing preview mannequin.
const mannequin = [
  [0, 4.2, 0, .83, .85, .78, 'head'],
  [0, 3.12, 0, 1.29, 1.18, .71, 'shirt'],
  [0, 2.37, 0, 1.2, .38, .66, 'pants'],
  [-.85, 2.85, 0, .35, 1.43, .47, 'shirt'],
  [.85, 2.85, 0, .35, 1.43, .47, 'shirt'],
  [-.32, 1.25, 0, .55, 1.94, .57, 'pants'],
  [.32, 1.25, 0, .55, 1.94, .57, 'pants'],
  [-.32, .15, .1, .56, .3, .77, 'boots'],
  [.32, .15, .1, .56, .3, .77, 'boots'],
] as const;

const materials = {
  head: ['#839194', '#6c7b80', '#a4acaf'],
  shirt: ['#425b69', '#344957', '#59717d'],
  pants: ['#293d4e', '#213344', '#3b5160'],
  boots: ['#293036', '#202930', '#3c474d'],
};

const faces = [
  [4, 5, 6, 7, 0],
  [1, 0, 3, 2, 0],
  [5, 1, 2, 6, 1],
  [0, 4, 7, 3, 1],
  [7, 6, 2, 3, 2],
  [0, 1, 5, 4, 1],
] as const;

export function addMannequin(context: CanvasRenderingContext2D, project: Projection, queue: DrawItem[]): void {
  for (const [x, y, z, width, height, depth, material] of mannequin) {
    const left = x - width / 2, right = x + width / 2;
    const bottom = y - height / 2, top = y + height / 2;
    const back = z - depth / 2, front = z + depth / 2;
    const corners = [
      project(left, bottom, back), project(right, bottom, back),
      project(right, top, back), project(left, top, back),
      project(left, bottom, front), project(right, bottom, front),
      project(right, top, front), project(left, top, front),
    ];
    for (const [aIndex, bIndex, cIndex, dIndex, shade] of faces) {
      const a = corners[aIndex];
      const b = corners[bIndex];
      const c = corners[cIndex];
      const d = corners[dIndex];
      if ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x) >= 0) continue;
      queue.push({ depth: (a.depth + b.depth + c.depth + d.depth) / 4, draw() {
        context.beginPath();
        context.moveTo(a.x, a.y);
        context.lineTo(b.x, b.y);
        context.lineTo(c.x, c.y);
        context.lineTo(d.x, d.y);
        context.closePath();
        context.fillStyle = materials[material][shade];
        context.fill();
        context.strokeStyle = '#17242b';
        context.lineWidth = .8;
        context.stroke();
      } });
    }
  }
}
