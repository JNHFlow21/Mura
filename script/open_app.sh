#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -x .build/app/DesktopMemoryWallApp.app/Contents/MacOS/DesktopMemoryWallApp ]; then
  script/package_app.sh >/dev/null
fi
pkill -x DesktopMemoryWallApp || true
sleep 1
/usr/bin/open -n "$PWD/.build/app/DesktopMemoryWallApp.app"
sleep 1
pgrep -x DesktopMemoryWallApp >/dev/null
echo "Opened $PWD/.build/app/DesktopMemoryWallApp.app"
