import test from 'node:test';
import assert from 'node:assert/strict';
function encodeMessage(message) { return JSON.stringify({ payload: {}, ...message }); }
test('encodes bridge messages as JSON', () => {
  assert.equal(JSON.parse(encodeMessage({ kind: 'ready' })).kind, 'ready');
});
