import assert from 'node:assert/strict';
import test from 'node:test';
import { clientToBoard, distanceToSegment, fitCanvas, pointBounds, strokeContainsPoint } from '../canvas/geometry.js';

test('maps scaled editor coordinates back to board pixels', () => {
  const point = clientToBoard({ x: 260, y: 140 }, { left: 20, top: 20, width: 960, height: 540 }, { width: 3840, height: 2160 });
  assert.equal(point.x, 960);
  assert.equal(point.y, 480);
});

test('fits finite canvas without exceeding native size', () => {
  assert.deepEqual(fitCanvas({ width: 1000, height: 800 }, { width: 1920, height: 1080 }), { width: 1000, height: 563, scale: 0.5208333333333334 });
});

test('computes stroke bounds from board points', () => {
  assert.deepEqual(pointBounds([{ x: 12, y: 30 }, { x: 42, y: 10 }]), { x: 12, y: 10, width: 30, height: 20 });
});

test('hit-tests sparse strokes by segment not only recorded points', () => {
  const stroke = [{ x: 0, y: 0 }, { x: 100, y: 0 }];
  assert.equal(distanceToSegment({ x: 50, y: 8 }, stroke[0], stroke[1]), 8);
  assert.equal(strokeContainsPoint({ x: 50, y: 8 }, stroke, 12), true);
  assert.equal(strokeContainsPoint({ x: 50, y: 20 }, stroke, 12), false);
});
