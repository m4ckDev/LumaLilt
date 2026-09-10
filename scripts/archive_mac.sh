#!/bin/bash
# Create a local archive; uploading remains an explicit action in Xcode Organizer.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
    echo "Run this script on your Mac with full Xcode installed."
    exit 1
fi
if [[ -z "${DEVELOPER_DIR:-}" ]]; then
    if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
        export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
    elif [[ -d "$HOME/Downloads/Xcode.app/Contents/Developer" ]]; then
        export DEVELOPER_DIR="$HOME/Downloads/Xcode.app/Contents/Developer"
    fi
fi
mkdir -p build
/usr/bin/xcrun xcodebuild -list -json -project LumaLilt.xcodeproj >build/archive-project.json
python3 -c 'import json; p=json.load(open("build/archive-project.json")); assert "LumaLilt" in p["project"]["schemes"], "LumaLilt scheme not found"'
/usr/bin/xcrun xcodebuild -showBuildSettings -json -project LumaLilt.xcodeproj \
    -scheme LumaLilt -configuration Release -destination 'generic/platform=iOS' >build/archive-settings.json
python3 - <<'PY'
import json
settings = next(s["buildSettings"] for s in json.load(open("build/archive-settings.json")) if s["target"] == "LumaLilt")
if not settings.get("DEVELOPMENT_TEAM", "").strip():
    raise SystemExit("Select your existing Apple Developer team in Xcode > LumaLilt target > Signing & Capabilities, then rerun. No signing settings were changed.")
print("Archiving version " + settings["MARKETING_VERSION"] + " (" + settings["CURRENT_PROJECT_VERSION"] + ")")
PY
lumalilt_archive_dir=$(mktemp -d "$PWD/build/archive-XXXXXX")
echo "Creating archive. This can take several minutes..."
if /usr/bin/xcrun xcodebuild -project LumaLilt.xcodeproj -scheme LumaLilt \
    -configuration Release -destination 'generic/platform=iOS' -derivedDataPath build \
    -archivePath "$lumalilt_archive_dir/LumaLilt.xcarchive" archive >"$lumalilt_archive_dir/archive.log" 2>&1; then
    echo "PASS: $lumalilt_archive_dir/LumaLilt.xcarchive"
    open "$lumalilt_archive_dir/LumaLilt.xcarchive"
else
    tail -n 35 "$lumalilt_archive_dir/archive.log"
    echo "STOP: Archive failed. Full log: $lumalilt_archive_dir/archive.log"
    exit 1
fi
