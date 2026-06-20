import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const editorHTML = readFileSync(resolve(here, '../../../Sources/MemoryWallEditorBridge/Resources/Editor/index.html'), 'utf8');

test('places compact color control between eraser and undo', () => {
  const eraserIndex = editorHTML.indexOf('data-tool="eraser"');
  const colorIndex = editorHTML.indexOf('id="colorButton"');
  const undoIndex = editorHTML.indexOf('id="undo"');
  assert.ok(eraserIndex > 0, 'eraser tool exists');
  assert.ok(colorIndex > eraserIndex, 'color button follows eraser');
  assert.ok(undoIndex > colorIndex, 'undo follows color button');
  assert.match(editorHTML, /id="colorPalette"/);
  assert.ok(editorHTML.indexOf('class="paletteHeader"') < editorHTML.indexOf('id="swatchGrid"'), 'more color entry is anchored in the palette header');
  assert.match(editorHTML, /id="moreSwatchGrid"/);
  assert.match(editorHTML, /const COLOR_PRESETS = \[/);
  assert.match(editorHTML, /const MORE_COLOR_PRESETS = \[/);
  assert.match(editorHTML, /grid-template-columns: repeat\(10, 18px\)/);
  assert.match(editorHTML, /function morePaletteColors/);
  assert.doesNotMatch(editorHTML, /type="color"/);
});

test('color palette behavior is tool-aware', () => {
  assert.match(editorHTML, /colorButton\.disabled = disabled/);
  assert.match(editorHTML, /const disabled = tool === 'eraser'/);
  assert.match(editorHTML, /strokeColor: penColor/);
  assert.match(editorHTML, /strokeColor: textColor/);
  assert.match(editorHTML, /textEditor\.style\.color = textColor/);
  assert.match(editorHTML, /if \(isDeleteKey\(event\) && tool === 'select' && selectedId\)/);
});

test('color preferences persist through board metadata', () => {
  assert.match(editorHTML, /metadata\.editorPreferences/);
  assert.match(editorHTML, /function defaultEditorPreferences/);
  assert.match(editorHTML, /function persistEditorPreferences/);
  assert.match(editorHTML, /function loadEditorPreferencesFromBoard/);
  assert.match(editorHTML, /recentColors/);
});
