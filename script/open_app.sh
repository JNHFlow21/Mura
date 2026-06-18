#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -x .build/app/DesktopMemoryWallApp.app/Contents/MacOS/DesktopMemoryWallApp ]; then
  script/package_app.sh >/dev/null
fi
pkill -f DesktopMemoryWallApp || true
nohup "$PWD/.build/app/DesktopMemoryWallApp.app/Contents/MacOS/DesktopMemoryWallApp" >/tmp/DesktopMemoryWallApp.log 2>&1 &
sleep 1
pgrep -fl DesktopMemoryWallApp >/dev/null
