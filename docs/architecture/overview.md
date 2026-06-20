# Mura Architecture

Mura is a native macOS SwiftPM project that exports an editable finite board into a static wallpaper image. The core design intentionally rejects always-on overlays and live web wallpapers: after save or cancel, the WebView/editor is released and macOS displays a normal PNG wallpaper.

## Modules

- `MemoryWallCore`: portable board, element, display, and preference models.
- `MemoryWallWorkspace`: local file workspace, board store, snapshots, and audit log.
- `MemoryWallEditorBridge`: narrow WKWebView bridge plus bundled local canvas editor and font assets.
- `MemoryWallRenderer`: AppKit fallback PNG renderer with explicit render budgets.
- `MemoryWallWallpaper`: display discovery, wallpaper apply/restore boundary, hotkey facade.
- `MemoryWallAgentTools`: primitive command registry used by `dmwctl`.
- `DesktopMemoryWallApp`: thin SwiftUI menu bar shell and foreground edit window.

## Runtime Loop

1. UI or `dmwctl` loads the same active board JSON from the workspace.
2. Edit mode opens a blank finite canvas with minimal tools: select, text, pen, eraser, undo/redo, save, cancel.
3. Save receives board JSON plus PNG bytes from the web editor, persists both, records wallpaper snapshot metadata, and applies the PNG through `NSWorkspace`.
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
logs/audit.jsonl
docs/agent/context.md
```
