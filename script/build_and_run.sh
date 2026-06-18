#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
script/build_editor_assets.sh
app_path="$(script/package_app.sh | tail -n 1)"
open "$app_path"
echo "Opened $app_path"
