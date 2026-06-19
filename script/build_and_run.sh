#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
script/build_editor_assets.sh
script/package_app.sh >/dev/null
script/open_app.sh
