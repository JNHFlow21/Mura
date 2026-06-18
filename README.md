# Desktop Memory Wall

A lightweight macOS menu bar app that turns a large Excalidraw-like reminder board into a static desktop wallpaper. Edit mode uses a local bundled editor surface; save renders a PNG and applies it through macOS wallpaper APIs so idle state stays light.

## Build and test

```bash
script/build_editor_assets.sh
swift test
swift build
script/package_app.sh
```

Packaged app output:

```text
.build/app/DesktopMemoryWallApp.app
```

## Agent CLI

```bash
swift run dmwctl status --json
swift run dmwctl board patch --text "今天先完成最重要的一件事" --json
swift run dmwctl render preview --width 1920 --height 1080 --json
swift run dmwctl render preview --wallpaper --json
swift run dmwctl wallpaper apply --confirm --json
swift run dmwctl wallpaper restore --confirm --json
```

Use `--workspace /path/to/workspace` to test without touching the default app support workspace.
