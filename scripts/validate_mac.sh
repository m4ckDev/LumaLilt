#!/bin/bash
# Native validation only. Does not change signing, upload a build, or erase simulators.
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
/usr/bin/xcrun --find xcodebuild >/dev/null
mkdir -p build/validation
run_check() {
    local label="$1"
    local logfile="$2"
    shift 2
    echo "$label..."
    if "$@" >"$logfile" 2>&1; then
        echo "PASS: $label"
    else
        tail -n 35 "$logfile"
        echo "STOP: $label failed. Full log: $PWD/$logfile"
        exit 1
    fi
}
run_check "Project structure" build/validation/structure.log python3 scripts/check_project.py
run_check "Puzzle engine tests" build/validation/core.log /usr/bin/xcrun swift test --jobs 2
/usr/bin/xcrun xcodebuild -list -json -project LumaLilt.xcodeproj >build/validation/project.json
python3 -c 'import json; p=json.load(open("build/validation/project.json")); assert "LumaLilt" in p["project"]["schemes"], "LumaLilt scheme not found"'
/usr/bin/xcrun simctl list devices available -j >build/validation/devices.json
lumalilt_simulator=$(python3 - <<'PY'
import json
devices = [d for runtime, group in json.load(open("build/validation/devices.json"))["devices"].items()
           if ".iOS-" in runtime for d in group if d.get("isAvailable") and "iPhone" in d["name"]]
devices.sort(key=lambda d: ("iPhone SE" not in d["name"], d["state"] != "Booted", d["name"]))
if not devices:
    raise SystemExit("No available iPhone simulator. Install an iOS runtime in Xcode Settings > Components, then rerun.")
print(devices[0]["udid"])
PY
)
lumalilt_result_dir=$(mktemp -d "$PWD/build/validation/run-XXXXXX")
echo "Running native tests on simulator $lumalilt_simulator (Xcode may boot it)."
run_check "Native app build and tests" build/validation/native.log \
    /usr/bin/xcrun xcodebuild -project LumaLilt.xcodeproj -scheme LumaLilt \
    -destination "platform=iOS Simulator,id=$lumalilt_simulator" \
    -derivedDataPath build -resultBundlePath "$lumalilt_result_dir/Tests.xcresult" \
    -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
echo "Validation passed. Logs: $PWD/build/validation"
echo "Next: open LumaLilt.xcodeproj and test on your physical iPhone and iPad."
