#!/bin/zsh
set -eu
task_source_dir=${0:A:h}
task_output_dir=${WORK_REST_PREVIEW_OUTPUT:-/private/tmp/work-rest-timer-native-preview}
task_app_dir="$task_output_dir/Work Rest Timer Preview.app"
mkdir -p "$task_app_dir/Contents/MacOS" "$task_app_dir/Contents/Resources" "$task_output_dir/module-cache"
trap 'rm -rf "$task_output_dir/module-cache"' EXIT
swiftc -parse-as-library -O -module-cache-path "$task_output_dir/module-cache" \
  "$task_source_dir/TimerEngine.swift" "$task_source_dir/TimerStore.swift" \
  "$task_source_dir/DialView.swift" "$task_source_dir/TimerPanelView.swift" "$task_source_dir/App.swift" \
  -o "$task_app_dir/Contents/MacOS/work-rest-timer-preview"
cat > "$task_app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.simon.work-rest-timer.preview</string>
<key>CFBundleName</key><string>Work Rest Timer Preview</string>
<key>CFBundleDisplayName</key><string>Work Rest Timer Preview</string>
<key>CFBundleExecutable</key><string>work-rest-timer-preview</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
python3 "$task_source_dir/make-chime.py" "$task_app_dir/Contents/Resources/gentle-chime.wav"
printf '%s\n' "$task_app_dir"
