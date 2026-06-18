# Diagnostics

Run:

```bash
swift run dmwctl --workspace /tmp/dmw diagnostics --json
```

The diagnostics payload reports workspace path, active board identity, display count, latest render path, render existence, editor asset expectation, and recent audit count.

## Common Issues

### Missing editor asset

Run `script/build_editor_assets.sh`. The v1 editor asset is a local static HTML file copied into both the bridge target and the app resource bundle.

### Corrupt board JSON

`FileBoardStore` rejects corrupt board JSON with a recoverable error and does not overwrite snapshots. Restore from `snapshots/boards/` or apply a template.

### Wallpaper apply failed

Check that `renders/latest-wallpaper.png` exists, then retry `dmwctl wallpaper apply --confirm --json`. Previous wallpaper metadata is written before replacement so a later restore path exists after a successful apply attempt.

### Hotkey conflict

The current implementation keeps hotkey behavior behind `HotkeyService`. v1 uses an in-memory facade to avoid platform coupling; a real global hotkey package can replace it without touching workspace, renderer, or agent tools.
