import assert from 'node:assert/strict';
import test from 'node:test';
import { decodePNGDataURL, encodeMessage } from '../bridge/nativeBridge.js';

test('encodes export messages with board and payload', () => {
  const json = encodeMessage({ kind: 'exportPNG', board: { canvasWidth: 1920, canvasHeight: 1080 }, payload: { pngDataURL: 'data:image/png;base64,AAAA' } });
  const message = JSON.parse(json);
  assert.equal(message.kind, 'exportPNG');
  assert.equal(message.board.canvasWidth, 1920);
  assert.equal(decodePNGDataURL(message.payload.pngDataURL), 'AAAA');
});

test('rejects non-png exports', () => {
  assert.throws(() => decodePNGDataURL('data:image/jpeg;base64,AAAA'), /PNG/);
});
