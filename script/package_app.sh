#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${CONFIGURATION:-release}"

[ -s Sources/MemoryWallEditorBridge/Resources/Editor/index.html ] || { echo "missing editor index" >&2; exit 1; }
[ -s Sources/MemoryWallEditorBridge/Resources/Fonts/LXGWWenKai-Regular.ttf ] || { echo "missing LXGW WenKai font" >&2; exit 1; }
./script/build_editor_assets.sh >/dev/null
swift build --product Mura -c "$configuration"
bin_dir="$(swift build --show-bin-path -c "$configuration")"
app_dir=".build/app/Mura.app"
rm -rf ".build/app/DesktopMemoryWallApp.app"
rm -rf "$app_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$bin_dir/Mura" "$app_dir/Contents/MacOS/Mura"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>Mura</string>
  <key>CFBundleIdentifier</key><string>local.mura</string>
  <key>CFBundleIconFile</key><string>Mura</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>Mura</string>
  <key>CFBundleDisplayName</key><string>Mura</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
cp App/DesktopMemoryWallApp/Resources/Brand/Mura.icns "$app_dir/Contents/Resources/Mura.icns"
echo "APPL????" > "$app_dir/Contents/PkgInfo"
for bundle in "$bin_dir"/Mura_*.bundle; do
  [ -e "$bundle" ] || continue
  cp -R "$bundle" "$app_dir/Contents/Resources/"
  bundle_name="$(basename "$bundle" .bundle)"
  cat > "$app_dir/Contents/Resources/$bundle_name.bundle/Info.plist" <<BUNDLE_PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleIdentifier</key><string>local.mura.$bundle_name</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$bundle_name</string>
  <key>CFBundlePackageType</key><string>BNDL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
</dict></plist>
BUNDLE_PLIST
done
sanitize_bundle_xattrs() {
  # A checkout/build inside iCloud Drive can attach FinderInfo/resource-fork style
  # metadata to bundle directories. codesign rejects any such detritus, so clear
  # all extended attributes before signing.
  xattr -cr "$app_dir" 2>/dev/null || true
}
sanitize_bundle_xattrs
codesign --force --deep --sign - "$app_dir" >/dev/null
sanitize_bundle_xattrs
echo "$PWD/$app_dir"
