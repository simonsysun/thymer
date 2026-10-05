#!/bin/zsh
set -eu
study_source=${0:A:h}
study_checks=$(mktemp -d /private/tmp/work-rest-drag-check.XXXXXX)
trap 'rm -rf "$study_checks"' EXIT
swiftc -parse-as-library -module-cache-path "$study_checks/cache" "$study_source/DialDrag.swift" "$study_source/DragChecks.swift" -o "$study_checks/check"
"$study_checks/check"
