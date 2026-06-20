# Mura

A lightweight macOS menu bar app that turns a blank finite canvas into a static desktop wallpaper. Edit mode opens like a clean Excalidraw-style board: write text, doodle with the pen, erase or move elements, then save the exact canvas pixels as the wallpaper. After save/cancel, the editor WebView is released so idle cost stays low.


## Download and install

Download `Mura-v1.dmg` from the GitHub Release, open it, and drag `Mura.app` into `/Applications`.

This v1 build is ad-hoc signed only and is not Apple notarized yet. If macOS says the app is damaged, cannot be opened, or the developer cannot be verified, install it first and then run:

```bash
sudo xattr -rd com.apple.quarantine /Applications/Mura.app
open /Applications/Mura.app
```

Only run the command for a `Mura.app` downloaded from the official GitHub Release.

## Build and test

```bash
script/build_editor_assets.sh
npm --prefix EditorWeb test
swift test
swift build
script/package_app.sh
script/package_dmg.sh v1
```

Packaged app output:

```text
.build/app/Mura.app
dist/Mura-v1.dmg
```

## Agent CLI

```bash
swift run dmwctl status --json
swift run dmwctl board blank --width 1920 --height 1080 --json
swift run dmwctl board patch --text "今天先完成最重要的一件事" --x 120 --y 120 --json
swift run dmwctl board stroke --points "120,240;240,300;360,260" --json
swift run dmwctl render preview --width 1920 --height 1080 --json
swift run dmwctl render preview --wallpaper --json
swift run dmwctl wallpaper apply --confirm --json
swift run dmwctl wallpaper restore --confirm --json
```

Use `--workspace /path/to/workspace` to test without touching the default app support workspace.

## Product shape

- First launch is blank: no planner template and no prefilled text.
- The board stores finite desktop-pixel dimensions (`canvasWidth`, `canvasHeight`).
- Text uses bundled LXGW WenKai for Chinese, English, and digits.
- The app save path uses the editor-exported PNG as the wallpaper source of truth.
