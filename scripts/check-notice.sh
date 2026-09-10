#!/bin/zsh
set -eu
project_dir=${0:A:h:h}
task_dir=$(mktemp -d /private/tmp/work-rest-notice-check.XXXXXX)
trap 'rm -rf "$task_dir"' EXIT
swiftc -parse-as-library -module-cache-path "$task_dir/cache" "$project_dir/Sources/PhaseNoticeContent.swift" "$project_dir/Tests/NoticeChecks.swift" -o "$task_dir/check"
"$task_dir/check"
