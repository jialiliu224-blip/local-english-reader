#!/bin/zsh
set -eu
project_dir="${0:A:h:h}"
bundle="$project_dir/build/Local English Reader.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources" "$project_dir/build/module-cache"
swiftc -target arm64-apple-macos26.0 -module-cache-path "$project_dir/build/module-cache" \
 "$project_dir/src/ReaderState.swift" "$project_dir/src/SelectionPolicy.swift" \
 "$project_dir/src/GlobalHotKey.swift" "$project_dir/src/PresentationPolicy.swift" \
 "$project_dir/src/ResultPanel.swift" "$project_dir/src/Lexicon.swift" \
 "$project_dir/src/VoiceConfiguration.swift" "$project_dir/src/App.swift" \
 -o "$bundle/Contents/MacOS/EnglishReader"
cp "$project_dir"/src/*.py "$bundle/Contents/Resources/"
cp "$project_dir/Info.plist" "$bundle/Contents/Info.plist"
codesign --force --sign - "$bundle"
codesign --verify --strict "$bundle"
print 'Built build/Local English Reader.app (local ad-hoc signature; not notarized)'
