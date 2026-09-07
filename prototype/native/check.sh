#!/bin/zsh
set -eu
task_source_dir=${0:A:h}
task_check_dir=$(mktemp -d /private/tmp/work-rest-timer-check.XXXXXX)
trap 'rm -rf "$task_check_dir"' EXIT
swiftc -parse-as-library -module-cache-path "$task_check_dir/module-cache" \
  "$task_source_dir/TimerEngine.swift" "$task_source_dir/EngineChecks.swift" -o "$task_check_dir/engine-checks"
"$task_check_dir/engine-checks"
