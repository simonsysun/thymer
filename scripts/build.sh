#!/bin/zsh
set -eu
project_dir=${0:A:h:h}
output_dir=${WORK_REST_BUILD_DIR:-"$project_dir/dist"}
app_dir="$output_dir/Thymer.app"
cache_dir=$(mktemp -d /private/tmp/work-rest-build.XXXXXX)
trap 'rm -rf "$cache_dir"' EXIT
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
iconset_dir="$cache_dir/AppIcon.iconset"
mkdir -p "$iconset_dir"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$project_dir/docs/brand/app-icon/thymer-app-icon-v1.png" --out "$iconset_dir/icon_${size}x${size}.png" >/dev/null
  retina_size=$((size * 2))
  sips -z "$retina_size" "$retina_size" "$project_dir/docs/brand/app-icon/thymer-app-icon-v1.png" --out "$iconset_dir/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset_dir" -o "$app_dir/Contents/Resources/AppIcon.icns"
swiftc -parse-as-library -O -module-cache-path "$cache_dir" -I "$project_dir/Sources/CSQLite" "$project_dir"/Sources/*.swift -o "$app_dir/Contents/MacOS/work-rest-timer"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.simonsysun.work-rest-timer</string>
<key>CFBundleName</key><string>Thymer</string>
<key>CFBundleDisplayName</key><string>Thymer</string>
<key>CFBundleExecutable</key><string>work-rest-timer</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleIconFile</key><string>AppIcon.icns</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(date -u +%Y%m%d%H%M%S)" "$app_dir/Contents/Info.plist"
python3 "$project_dir/prototype/native/make-chime.py" "$app_dir/Contents/Resources/gentle-chime.wav"
codesign --force --sign - "$app_dir"
printf '%s\n' "$app_dir"
