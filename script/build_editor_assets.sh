#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p App/DesktopMemoryWallApp/Resources/Editor
cp Sources/MemoryWallEditorBridge/Resources/Editor/index.html App/DesktopMemoryWallApp/Resources/Editor/index.html
if command -v npm >/dev/null 2>&1; then
  (cd EditorWeb && npm test)
fi
echo "Editor assets ready."
