#!/bin/zsh
set -eu
project_dir=${0:A:h:h}
task_dir=$(mktemp -d /private/tmp/work-rest-check-build.XXXXXX)
trap 'rm -rf "$task_dir"' EXIT
swiftc -parse-as-library -module-cache-path "$task_dir/cache" -I "$project_dir/Sources/CSQLite" "$project_dir/Sources/TimerModel.swift" "$project_dir/Sources/Database.swift" "$project_dir/Sources/TimerStore.swift" "$project_dir/Sources/DialDrag.swift" "$project_dir/Sources/DialSectors.swift" "$project_dir/Tests/CoreChecks.swift" -o "$task_dir/check"
"$task_dir/check"

swiftc -parse-as-library -module-cache-path "$task_dir/cache" -I "$project_dir/Sources/CSQLite" "$project_dir/Sources/TimerModel.swift" "$project_dir/Sources/Database.swift" "$project_dir/Tests/DatabaseChecks.swift" -o "$task_dir/database-check"
"$task_dir/database-check"
