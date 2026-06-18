#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${CONFIGURATION:-release}"
swift build --product DesktopMemoryWallApp -c "$configuration"
bin_dir="$(swift build --show-bin-path -c "$configuration")"
app_dir=".build/app/DesktopMemoryWallApp.app"
rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$bin_dir/DesktopMemoryWallApp" "$app_dir/Contents/MacOS/DesktopMemoryWallApp"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>DesktopMemoryWallApp</string>
  <key>CFBundleIdentifier</key><string>local.desktop-memory-wall</string>
  <key>CFBundleName</key><string>Desktop Memory Wall</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
for bundle in "$bin_dir"/DesktopMemoryWall_*.bundle; do
  [ -e "$bundle" ] || continue
  cp -R "$bundle" "$app_dir/"
  cp -R "$bundle" "$app_dir/Contents/Resources/"
done
echo "$PWD/$app_dir"
