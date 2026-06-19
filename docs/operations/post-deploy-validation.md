# Post-Deploy Monitoring & Validation

This is a local macOS app with no server deployment. Validation is local and file/workspace based.

## Validation Window

Owner: local user / agent operating the machine. Window: first 24 hours of normal desktop use after installing the packaged app.

## Healthy Signals

- Edit mode opens a blank warm off-white finite canvas, not a prefilled planner template.
- `dmwctl diagnostics --json` returns `ok: true` and reports editor/font readiness.
- `renders/latest-wallpaper.png` or `renders/previews/*.png` exist after save/render commands.
- `logs/audit.jsonl` receives `board.save`, `render.preview`, `wallpaper.apply`, and `wallpaper.restore` events as actions are used.
- Activity Monitor shows near-zero CPU while idle and no edit window is open.

## Failure Signals

- Editor window cannot load local `index.html` or `LXGWWenKai-Regular.ttf` asset.
- Save applies a PNG with dimensions that do not match the active display.
- `wallpaper restore` cannot find a snapshot after a successful apply.
- App retains an editor window/WebView after save/cancel.

## Rollback / Mitigation

- Run `swift run dmwctl wallpaper restore --confirm --json` to restore the last captured wallpaper.
- Use a temp workspace with `--workspace /tmp/dmw-test` for diagnosis before touching the real workspace.
- If packaged resources are missing, rerun `script/build_editor_assets.sh` and `script/package_app.sh`.
