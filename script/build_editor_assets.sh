#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p App/DesktopMemoryWallApp/Resources/Editor App/DesktopMemoryWallApp/Resources/Fonts
cp Sources/MemoryWallEditorBridge/Resources/Editor/index.html App/DesktopMemoryWallApp/Resources/Editor/index.html
cp Sources/MemoryWallEditorBridge/Resources/Fonts/LXGWWenKai-Regular.ttf App/DesktopMemoryWallApp/Resources/Fonts/LXGWWenKai-Regular.ttf
if command -v npm >/dev/null 2>&1; then
  (cd EditorWeb && npm test)
fi
echo "Editor assets ready."
