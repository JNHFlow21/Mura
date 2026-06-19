# Handoff: Desktop Memory Wall editor still failing

Date: 2026-06-19
Repo: `desktop-memory-wall`
Branch: `feat/desktop-memory-wall`

## User-visible failure

The user reports the current build is still failing after the latest fix:

- Selecting `文字` does not let the user input text onto the canvas.
- Selecting `画笔` can draw visibly in the editor, but the drawing does not persist/apply to the desktop after save.
- Earlier visible error was: `Invalid editor bridge message: The data couldn’t be read because it isn’t in the correct format.` That red error stopped appearing after `31fef35`, but the functional failure remains.

## Current commits

- `0eb30d2 docs: plan multi-display modes`
- `31fef35 fix: stabilize editor bridge loading`
- `afe3b2b feat: replace templates with finite canvas editor`
- `aa382e9 fix: make memory wall launch visible`
- `ba12f31 feat: build desktop memory wall`

## Important files

Editor bridge and canvas:

- `Sources/MemoryWallEditorBridge/EditorBridge.swift`
- `Sources/MemoryWallEditorBridge/WebEditorCoordinator.swift`
- `Sources/MemoryWallEditorBridge/WebEditorView.swift`
- `Sources/MemoryWallEditorBridge/Resources/Editor/index.html`
- `App/DesktopMemoryWallApp/Resources/Editor/index.html`
- `App/DesktopMemoryWallApp/ViewModels/AppStateStore.swift`
- `App/DesktopMemoryWallApp/Scenes/EditWindowScene.swift`

Tests and scripts:

- `Tests/MemoryWallEditorBridgeTests/EditorBridgeTests.swift`
- `EditorWeb/src/__tests__/exportBoard.test.js`
- `EditorWeb/src/__tests__/canvasGeometry.test.js`
- `script/build_editor_assets.sh`
- `script/package_app.sh`
- `script/open_app.sh`

Plans:

- `docs/plans/2026-06-19-002-feat-finite-canvas-editor-plan.md`
- `docs/plans/2026-06-19-003-feat-multi-display-modes-plan.md`

## What was changed recently

`31fef35` attempted to stabilize the bridge by:

- Supporting fractional-second ISO dates from JavaScript `new Date().toISOString()`.
- Avoiding full-board payloads on `ready` and `boardChanged`.
- Adding `lastLoadedBoardJSON` so SwiftUI status updates do not reload the same board repeatedly.
- Caching `window.__memoryWallNativeBoardJSON` if Swift injects board JSON before `window.memoryWallLoadBoard` is ready.

Validation passed but was insufficient because it did not perform real interactive WebView input/save testing:

```bash
npm test
swift test
script/package_app.sh
```

## Likely failure areas to inspect first

1. **Text input path in the HTML editor**
   - `startTextEditor(point, existing)` should display and focus `#textEditor`.
   - `commitTextEditor()` is bound to `blur`, which may fire immediately if focus is stolen by the WKWebView or toolbar state updates.
   - If blur fires before typing, the empty text element is deleted immediately.
   - Inspect whether `textEditor.style.display = 'block'` actually happens, and whether `document.activeElement === textEditor` after clicking the canvas in text mode.

2. **Save/export path from Web to Swift**
   - `save()` calls `exportPNG()` then posts `kind: 'exportPNG'` with `{ board, payload: { pngDataURL, width, height, fontReady } }`.
   - `AppStateStore.saveExportAndApplyWallpaper(_:)` requires `message.board` and `pngDataURL`.
   - Add logging or a temporary diagnostics message to confirm Swift receives `exportPNG` and whether `message.board.elements` includes freedraw/text elements.

3. **WKScriptMessage body type**
   - `WebEditorCoordinator` expects `message.body as? String`.
   - Current JS calls `postMessage(JSON.stringify(message))`, so this should be a string, but verify in live WebView.

4. **App resource freshness**
   - `script/build_editor_assets.sh` must copy `Sources/MemoryWallEditorBridge/Resources/Editor/index.html` to `App/DesktopMemoryWallApp/Resources/Editor/index.html`.
   - `script/package_app.sh` runs that script, but `script/open_app.sh` may be opening an older packaged app or already-running app process if not killed first.

5. **Wallpaper apply target**
   - Current app applies to `displayService.mainDisplay()` only.
   - If save writes PNG but user does not see it, inspect `~/Library/Application Support/DesktopMemoryWall/renders/latest-wallpaper.png` and `logs/audit.jsonl`.

## Suggested debug workflow

Use a real interactive test, not only unit tests:

1. Kill stale app processes:

```bash
pkill -x DesktopMemoryWallApp || true
```

2. Rebuild and open:

```bash
script/build_editor_assets.sh
script/package_app.sh
script/open_app.sh
```

3. Add temporary bridge diagnostics if needed:

- Log raw `WKScriptMessage.body` in `WebEditorCoordinator.userContentController`.
- Log `message.kind`, `message.board?.elements.count`, and export PNG byte count in `AppStateStore.handleEditorMessage` / `saveExportAndApplyWallpaper`.
- Add a visible editor status line update in `startTextEditor`, `commitTextEditor`, `pointerdown`, and `save`.

4. Verify artifacts after save:

```bash
ls -lh "$HOME/Library/Application Support/DesktopMemoryWall/renders/latest-wallpaper.png"
tail -50 "$HOME/Library/Application Support/DesktopMemoryWall/logs/audit.jsonl"
cat "$HOME/Library/Application Support/DesktopMemoryWall/boards/active-board.json" | python3 -m json.tool | head -120
```

5. If `latest-wallpaper.png` exists, inspect it directly before blaming wallpaper apply.

## Multi-display plan status

The user explicitly rejected stitched large-canvas mode. The only planned modes are:

- Mirror sync: edit one board, export/apply one wallpaper per display.
- Independent displays: one board per display.

The plan is already written at:

`docs/plans/2026-06-19-003-feat-multi-display-modes-plan.md`

Do not start implementing multi-display until the basic editor text/save bug is fixed.

## Current validation status

Last known automated checks passed before the user reported the failure:

- `npm test` passed: 6 tests.
- `swift test` passed: 29 tests.
- `script/package_app.sh` completed.

These tests do not prove real WKWebView interaction works.

## Recommended next action

Run a focused `ce-debug` or direct debug pass on the live editor interaction:

- First make text insertion work reliably.
- Then make save persist text and freedraw elements to `active-board.json` and `latest-wallpaper.png`.
- Only after that, proceed to `ce-work` for the multi-display plan.
