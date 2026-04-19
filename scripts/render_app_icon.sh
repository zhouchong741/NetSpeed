#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"
master_icon="${1:-$root_dir/macos/AppIconMaster.png}"
icon_dir="$root_dir/macos"
iconset_dir="$icon_dir/AppIcon.iconset"

if [[ ! -f "$master_icon" ]]; then
  echo "Error: master icon not found at $master_icon" >&2
  exit 1
fi

rm -rf "$iconset_dir"
mkdir -p "$iconset_dir"

generate_png() {
  local size="$1"
  local destination="$2"
  sips -s format png -z "$size" "$size" "$master_icon" --out "$destination" >/dev/null
}

generate_png 16 "$icon_dir/AppIcon16.png"
generate_png 32 "$icon_dir/AppIcon32.png"
generate_png 64 "$icon_dir/AppIcon64.png"
generate_png 128 "$icon_dir/AppIcon128.png"
generate_png 256 "$icon_dir/AppIcon256.png"
generate_png 512 "$icon_dir/AppIcon512.png"
generate_png 1024 "$icon_dir/AppIcon1024.png"

generate_png 16 "$iconset_dir/icon_16x16.png"
generate_png 32 "$iconset_dir/icon_16x16@2x.png"
generate_png 32 "$iconset_dir/icon_32x32.png"
generate_png 64 "$iconset_dir/icon_32x32@2x.png"
generate_png 128 "$iconset_dir/icon_128x128.png"
generate_png 256 "$iconset_dir/icon_128x128@2x.png"
generate_png 256 "$iconset_dir/icon_256x256.png"
generate_png 512 "$iconset_dir/icon_256x256@2x.png"
generate_png 512 "$iconset_dir/icon_512x512.png"
generate_png 1024 "$iconset_dir/icon_512x512@2x.png"

iconutil -c icns "$iconset_dir" -o "$icon_dir/AppIcon.icns"
rm -rf "$iconset_dir"

echo "Generated icon assets from $master_icon"
