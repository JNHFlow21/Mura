#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -x .build/app/Mura.app/Contents/MacOS/Mura ]; then
  script/package_app.sh >/dev/null
fi
pkill -x Mura || true
pkill -x DesktopMemoryWallApp || true
sleep 1
/usr/bin/open -n "$PWD/.build/app/Mura.app"
sleep 1
pgrep -x Mura >/dev/null
echo "Opened $PWD/.build/app/Mura.app"
