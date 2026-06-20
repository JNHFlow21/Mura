#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

version="${1:-v1}"
app_name="Mura"
output_dir="${OUTPUT_DIR:-dist}"
app_path=".build/app/${app_name}.app"
dmg_path="${output_dir}/${app_name}-${version}.dmg"

mkdir -p "$output_dir"
./script/package_app.sh >/dev/null

staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/mura-dmg.XXXXXX")"
cleanup() { rm -rf "$staging_dir"; }
trap cleanup EXIT

/usr/bin/ditto --norsrc "$app_path" "$staging_dir/${app_name}.app"
find "$staging_dir/${app_name}.app" -exec xattr -d com.apple.FinderInfo {} \; 2>/dev/null || true
find "$staging_dir/${app_name}.app" -exec xattr -d com.apple.ResourceFork {} \; 2>/dev/null || true
find "$staging_dir/${app_name}.app" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true
find "$staging_dir/${app_name}.app" -exec xattr -d com.apple.provenance {} \; 2>/dev/null || true
xattr -d com.apple.FinderInfo "$staging_dir/${app_name}.app" 2>/dev/null || true
ln -s /Applications "$staging_dir/Applications"
cat > "$staging_dir/README.txt" <<README
${app_name} ${version}

Install:
1. Drag ${app_name}.app into Applications.
2. Open ${app_name} from Applications.

Unsigned build note:
This app is ad-hoc signed only and is not Apple notarized yet. If macOS says the app
is damaged, cannot be opened, or the developer cannot be verified, you can remove
the quarantine flag after installing it:

sudo xattr -rd com.apple.quarantine /Applications/${app_name}.app
open /Applications/${app_name}.app

Only run that command for a ${app_name}.app downloaded from the official GitHub release.
README

rm -f "$dmg_path"
hdiutil create \
  -volname "${app_name} ${version}" \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDZO \
  "$dmg_path" >/dev/null

shasum -a 256 "$dmg_path" > "$dmg_path.sha256"
echo "$PWD/$dmg_path"
