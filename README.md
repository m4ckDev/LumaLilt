# LumaLilt

**A little color. A quieter mind.**

An offline solo color puzzle for iPhone and iPad by MacKinnonTech.
Planned price: US $1.99 upfront, with no accounts, ads, subscriptions, or backend.

## Build 4: place two tiles, preserve the rest

Tap a tile, then any other tile to exchange their positions. Only those two tiles move,
including diagonal swaps. Arrange numbers left to right, top to bottom to restore the gradient.

- One swap is one move; one Undo reverses the entire swap while a puzzle is active.
- Hint puts a misplaced tile home and never disturbs a tile already home.
- A pinned target preview stays available while scrolling; tap it to enlarge.
- Tiles animate between their actual positions. Reduce Motion disables the transition.
- First launch after this update offers a two-swap guided practice, also available from Help.
- Stronger color separation, readable optional number labels, and centered primary buttons.
- Optional move count stays off by default. No timer or move penalties.
- Gentle 3×3, Flowing 4×4, Deep 5×5; a daily 4×4 puzzle refreshes at midnight UTC.
- Local saved progress, completion history, palettes, haptics, and result sharing.

**Release instructions:** [Build 4 Mac and App Store handoff](docs/BUILD_4_HANDOFF.md).
**Listing text:** [App Store copy](docs/APP_STORE.md).

## Open locally

Use a fresh sibling checkout to keep existing signing edits safe:

```bash
git clone https://github.com/m4ckDev/LumaLilt.git "$HOME/Developer/LumaLilt-build4"
cd "$HOME/Developer/LumaLilt-build4"
open LumaLilt.xcodeproj
```

If the folder already exists, stop and inspect it; do not delete it or reset local changes.
Choose your existing team in Signing & Capabilities. Keep `com.mackinnontech.LumaLilt`.
Version is **1.0**, build **4**. The checked-in project and icon are ready to open.

- Command-R: run on your selected simulator or connected device.
- Command-U: run engine and native UI tests, using a simulator destination.
- `bash scripts/validate_mac.sh`: quiet engine and native simulator tests with detailed logs.
- `bash scripts/archive_mac.sh`: archive with your existing signing and open Organizer.

Xcode is required for the app. No third-party runtime dependencies, API keys, or server are needed.
Deployment target is iOS/iPadOS 16+. Use the Xcode/SDK version currently accepted by Apple.

## Validation

GitHub Actions runs the production Swift core tests, builds the native app, and runs XCTest
and XCUITest on an available iPhone simulator. UI tests exercise the guided practice, diagonal
swaps, single Undo, hints and the target sheet. CI retains result bundles and screenshots.

Core coverage includes 600 seeded puzzles, every pair of positions at every board size,
monotonic hints preserving correct tiles, invalid inputs, undo/restart, deterministic dates,
save round trips, old-save migration, malformed saves, and palettes.

These checks do not measure human enjoyment, device frame rate, or substitute for physical-device
QA. See [validation checklist](docs/VALIDATION.md) and the workflow results for the tested commit.

## Save compatibility

Builds 1–3 saved whole-line puzzles. Build 4 keeps their exact current boards, IDs, counters,
completion history and existing undo snapshots, and allows them to be finished using swaps.
Reset still restores the old puzzle's original scramble. New puzzles use a deterministic
Fisher–Yates permutation, solvable with pair swaps. A migrated in-progress daily puzzle may
therefore differ from a fresh build-4 install on the same UTC day; the next day aligns them.

New saves use puzzle rules version 2. They are intended for build 4 and later; do not downgrade
and expect build 3 to read them. Unknown or malformed saves are preserved by the existing storage
error handling instead of being overwritten. Hint use survives Undo and Reset. Completed puzzles
are locked, and their wins are recorded once.

## Layout

- `LumaLilt/Core/`: production rules, colors, save models.
- `LumaLilt/Views/`: gameplay, guided practice, home, collection and settings.
- `Tests/`: core XCTest coverage, also runnable with `swift test`.
- `UITests/`: native interaction tests.
- `scripts/`: metadata checks, native validation and archive helpers.
- `docs/`: release handoff, App Store copy, privacy and device QA.

The optional `scripts/generate_project.py` regenerates project metadata. It does not preserve
manual project-only signing edits; the generated project is already committed.

Copyright © 2026 Jonnathan R. MacKinnon. All rights reserved.
