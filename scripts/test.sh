#!/bin/zsh
set -eu
project_dir="${0:A:h:h}"
mkdir -p "$project_dir/build/tests" "$project_dir/build/module-cache"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONPATH="$project_dir/src"
python3 -m unittest discover -s "$project_dir/tests" -p '*Tests.py'
for pair in ReaderState:StateTests SelectionPolicy:SelectionPolicyTests PresentationPolicy:PresentationTests Lexicon:LexiconTests VoiceConfiguration:VoiceConfigurationTests; do
 source_name="${pair%%:*}"
 test_name="${pair##*:}"
 swiftc -module-cache-path "$project_dir/build/module-cache" "$project_dir/src/$source_name.swift" "$project_dir/tests/$test_name.swift" -o "$project_dir/build/tests/$test_name"
 "$project_dir/build/tests/$test_name"
done
