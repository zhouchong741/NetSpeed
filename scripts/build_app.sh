#!/bin/zsh

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"
app_name="NetSpeed"
build_dir="$root_dir/.build/release"
bundle_dir="$root_dir/dist/$app_name.app"
icon_source="$root_dir/macos/AppIcon.icns"
master_icon="$root_dir/macos/AppIconMaster.png"
icon_render_script="$root_dir/scripts/render_app_icon.sh"
no_build=false

if [[ "${1:-}" == "--no-build" ]]; then
  no_build=true
fi

binary_path=""
staged_binary_path=""
temp_dir=""

if [[ "$no_build" == "true" ]]; then
  if [[ -x "$bundle_dir/Contents/MacOS/$app_name" ]]; then
    binary_path="$bundle_dir/Contents/MacOS/$app_name"
  elif [[ -x "$build_dir/$app_name" ]]; then
    binary_path="$build_dir/$app_name"
  else
    echo "Error: no prebuilt binary found. Expected one of:"
    echo "  $bundle_dir/Contents/MacOS/$app_name"
    echo "  $build_dir/$app_name"
    exit 1
  fi
else
  binary_path="$build_dir/$app_name"
  echo "Building $app_name in release mode..."
  swift build -c release --package-path "$root_dir"
fi

if [[ -f "$master_icon" && -x "$icon_render_script" ]]; then
  "$icon_render_script" "$master_icon" >/dev/null
fi

if [[ ! -f "$icon_source" ]]; then
  echo "Error: icon file not found at $icon_source"
  exit 1
fi

echo "Packaging app bundle..."
if [[ "$no_build" == "true" && "$binary_path" == "$bundle_dir/Contents/MacOS/$app_name" ]]; then
  temp_dir="$(mktemp -d)"
  staged_binary_path="$temp_dir/$app_name"
  cp "$binary_path" "$staged_binary_path"
  binary_path="$staged_binary_path"
fi

rm -rf "$bundle_dir"
mkdir -p "$bundle_dir/Contents/MacOS" "$bundle_dir/Contents/Resources"

cp "$binary_path" "$bundle_dir/Contents/MacOS/$app_name"
cp "$root_dir/Support/Info.plist" "$bundle_dir/Contents/Info.plist"
cp "$icon_source" "$bundle_dir/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "$bundle_dir" >/dev/null 2>&1 || true

if [[ -n "$temp_dir" ]]; then
  rm -rf "$temp_dir"
fi

packaged_archs="$(lipo -archs "$bundle_dir/Contents/MacOS/$app_name")"
host_arch="$(uname -m)"
if [[ "$packaged_archs" != *"$host_arch"* ]]; then
  echo "Error: packaged binary architectures '$packaged_archs' do not include host architecture '$host_arch'" >&2
  exit 1
fi

echo "Packaged architectures: $packaged_archs"
echo "Created: $bundle_dir"
