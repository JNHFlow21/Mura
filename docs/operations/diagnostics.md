# Diagnostics

Run:

```bash
swift run dmwctl --workspace /tmp/dmw diagnostics --json
```

The diagnostics payload reports workspace path, active board identity, finite canvas dimensions, display count, latest render path, render existence, editor asset existence, bundled LXGW WenKai font existence, and recent audit count.

## Common Issues

### Missing editor asset or font asset

Run `script/build_editor_assets.sh`, then rerun `script/package_app.sh`. The v2 editor asset is a local static HTML canvas editor copied into both the bridge target and the app resource bundle. The LXGW WenKai font is required so edit and export typography match.

### Corrupt board JSON

`FileBoardStore` rejects corrupt board JSON with a recoverable error and does not overwrite snapshots. Restore from `snapshots/boards/` or create a new blank board with `dmwctl board blank --json`.

### Wallpaper apply failed

Check that `renders/latest-wallpaper.png` exists, then retry `dmwctl wallpaper apply --confirm --json`. Previous wallpaper metadata is written before replacement so a later restore path exists after a successful apply attempt.

### Hotkey conflict

The current implementation keeps hotkey behavior behind `HotkeyService`. A real global hotkey package can replace it without touching workspace, renderer, editor bridge, or agent tools.
