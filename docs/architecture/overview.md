# Desktop Memory Wall Architecture

Desktop Memory Wall is a native macOS SwiftPM project that renders an editable board into a static wallpaper image. The core design intentionally rejects always-on overlays and live web wallpapers: after save, the WebView/editor is released and macOS displays a normal PNG wallpaper.

## Modules

- `MemoryWallCore`: portable board, element, display, preferences, and template models.
- `MemoryWallWorkspace`: local file workspace, board store, template store, snapshots, and audit log.
- `MemoryWallEditorBridge`: narrow WKWebView bridge plus bundled local editor asset.
- `MemoryWallRenderer`: AppKit PNG renderer with explicit render budgets.
- `MemoryWallWallpaper`: display discovery, wallpaper apply/restore boundary, hotkey facade.
- `MemoryWallAgentTools`: primitive command registry used by `dmwctl`.
- `DesktopMemoryWallApp`: thin SwiftUI menu bar shell and foreground edit window.

## Runtime Loop

1. UI or `dmwctl` loads the same active board JSON from the workspace.
2. Edit mode uses the bundled local editor surface and a native text panel for large reminders.
3. Save persists the board, renders a display-sized PNG, records wallpaper snapshot metadata, and applies the image through `NSWorkspace`.
4. Idle state keeps only the lightweight menu bar app and file workspace; no editor WebView is needed.

## Workspace Contract

The default workspace lives at `~/Library/Application Support/DesktopMemoryWall`. Tests and agents can inject a different root with `--workspace`.

```text
boards/active-board.json
preferences.json
renders/latest-wallpaper.png
renders/previews/*.png
snapshots/boards/*.json
snapshots/wallpapers/*.json
templates/*.json
logs/audit.jsonl
docs/agent/context.md
```
