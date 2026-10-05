#!/bin/zsh
set -eu
study_source=${0:A:h}
study_output=$(mktemp -d /private/tmp/work-rest-glass-study.XXXXXX)
trap 'rm -rf "$study_output"' EXIT
swiftc -parse-as-library -module-cache-path "$study_output/cache" "$study_source/DialDrag.swift" "$study_source/GlassStudy.swift" -o "$study_output/glass-study"
rm -rf "$study_output/cache"
"$study_output/glass-study"
