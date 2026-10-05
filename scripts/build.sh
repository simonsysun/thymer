#!/bin/zsh
set -eu
project_dir=${0:A:h:h}
output_dir=${WORK_REST_BUILD_DIR:-"$project_dir/dist"}
app_dir="$output_dir/Work Rest Timer.app"
cache_dir=$(mktemp -d /private/tmp/work-rest-build.XXXXXX)
trap 'rm -rf "$cache_dir"' EXIT
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
swiftc -parse-as-library -O -module-cache-path "$cache_dir" -I "$project_dir/Sources/CSQLite" "$project_dir"/Sources/*.swift -o "$app_dir/Contents/MacOS/work-rest-timer"
cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.simonsysun.work-rest-timer</string>
<key>CFBundleName</key><string>Work Rest Timer</string>
<key>CFBundleDisplayName</key><string>Work Rest Timer</string>
<key>CFBundleExecutable</key><string>work-rest-timer</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
python3 "$project_dir/prototype/native/make-chime.py" "$app_dir/Contents/Resources/gentle-chime.wav"
codesign --force --sign - "$app_dir"
printf '%s\n' "$app_dir"
