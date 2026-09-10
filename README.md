# LumaLilt

**A little shift. A quieter mind.**

App three in MacKinnonTech's small-app collection, following Carry Splits and Nudge List.
A native, offline solo puzzle for iPhone and iPad, with an optional Mac Catalyst target.
Planned business model: **US $1.99 upfront**, no subscriptions, advertising, accounts, or backend costs.
Set the actual storefront price in App Store Connect; there is no in-app payment code.

## Play

Slide whole rows and columns to restore a color gradient. Tiles wrap around the edges.
Numbers show each tile's destination in reading order, so color perception is not required.
Tap a tile, then use the arrows, or swipe directly from a tile.

**Build 3:** tap a tile, then a destination in the same row or column to shift the
whole line by the shortest wraparound route. Labeled arrows and swipes remain
available. Stronger colors and readable number badges improve tile recognition;
the move counter is optional and hidden by default.

For the safe Mac update, test scripts, physical-device checklist, archive/upload,
and replacing the previous App Store build, see [Build 3 handoff](docs/BUILD_3_HANDOFF.md).

- Daily Lilt: a deterministic 4×4 puzzle, refreshed at midnight UTC.
- Free play: Gentle 3×3, Flowing 4×4, and Deep 5×5 boards.
- Every scramble comes from valid moves and has a known solution.
- Undo the last 100 turns, restart, or request a hint that performs one reverse-path move.
- Three palettes, optional number labels, gentle haptics, and Reduce Motion support.
- Saved daily and free-play sessions, completion history, and four milestone badges.
- Native share sheet for completed results.
- No timer, energy system, account, analytics, external assets, or network dependencies.

This is a first implementation, not an App Store release. Xcode compilation, simulator/device checks,
signing, and App Store submission are still required. The working title has not been reserved or
cleared as a trademark, and color-restoration puzzles are an existing genre.

## Open on your Mac

1. Extract `LumaLilt-Starter.zip`.
2. Open the extracted **LumaLilt** folder, then double-click **LumaLilt.xcodeproj**.
3. Select the **LumaLilt** scheme and an installed iPhone simulator in Xcode's top bar.
4. Press **Command-R** to build and run.
5. Press **Command-U** to run the included tests.

The Xcode project and app icon are already included. You do **not** need Homebrew, XcodeGen,
CocoaPods, a server, or an API key. Use Xcode 15 or later with its iOS SDK; the app targets iOS/iPadOS 16+.
Use the Xcode/SDK version Apple currently accepts when submitting a release.

To open it from Terminal, first change into the extracted folder, then run:

```bash
open LumaLilt.xcodeproj
```

For a physical iPhone, select the LumaLilt target → Signing & Capabilities → choose your Apple
Developer team. Change `com.mackinnontech.LumaLilt` if that identifier is unavailable in your account.
Connect/select the phone and run. For Mac Catalyst, select **My Mac (Mac Catalyst)**; this path also
needs its first native build and UI check. Haptics depend on device support.

## Code layout

```text
LumaLilt.xcodeproj/            Checked-in project and shared scheme
LumaLilt/
  LumaLiltApp.swift            Entry point and app lifecycle
  AppStore.swift               Local progress persistence and state
  Core/Puzzle.swift            Pure Swift board, moves, daily seed, undo, hints
  Core/Progress.swift          Completion history and deduplication
  Views/                      Play, game, collection, settings, shared styling
  Resources/                  App icon, accent asset, privacy manifest
Tests/PuzzleTests.swift        Game, palette and persistence regression tests
Package.swift                 Standalone core tests, no third-party packages
scripts/generate_project.py    Rebuild project metadata using Python 3
scripts/check_project.py       Dependency-free project and resource validation
scripts/validate_mac.sh        Quiet core + native simulator test workflow
scripts/archive_mac.sh         Archive using existing Xcode signing settings
docs/                         Release copy, privacy text, QA and handoff
.github/workflows/apple.yml    macOS CI: tests and iOS simulator build
```

## Validation

```bash
swift test
python3 scripts/check_project.py
xcodebuild -project LumaLilt.xcodeproj -scheme LumaLilt \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

`swift test` runs the exact production core independently of SwiftUI. Its tests cover 600 generated
boards, wraparound, inverse moves, hints after arbitrary moves, undo, restart, stable daily dates,
JSON persistence, win deduplication, and completed-board protection. These Swift tests were authored
but could not be executed in the generation environment, which has neither Swift nor Xcode.
See `docs/VALIDATION.md` for the checks actually performed and the manual release gate.

GitHub Actions runs the engine tests and builds the app/test bundle after the code is pushed.
It does not upload the app or claim a visual/device test.

Repository: https://github.com/m4ckDev/LumaLilt

## Important behavior

- Hints retrace the stored scramble/player path. They are guaranteed to reach a solution if repeated,
  but are not shortest-path hints and may undo a player's last move.
- Hint use remains recorded after undo/restart. Assisted completions are labeled accurately.
- Finishing a puzzle records its unique ID once. Completed puzzles are locked against further moves.
- Starting another unfinished free-play board asks before replacing it. Daily and free play save separately.
- Daily rollover replaces yesterday's in-progress daily board; completion history is retained.
- Daily puzzles use UTC, not the device's local midnight. The app checks when opened or foregrounded.
- Progress is atomically written to Application Support. Corrupt saves are preserved until the user
  explicitly resets progress; this session can still be played without overwriting them.
- Local stats are for enjoyment, not a tamper-resistant competitive leaderboard.
- Appearance preferences use UserDefaults. The privacy manifest declares the app-only UserDefaults reason.

## Clone from GitHub

On your Mac, run:

```bash
mkdir -p ~/Developer
cd ~/Developer
git clone https://github.com/m4ckDev/LumaLilt.git
cd LumaLilt
open LumaLilt.xcodeproj
```

If you already cloned this repository, update it from inside that checkout:

```bash
git pull --ff-only origin main
open LumaLilt.xcodeproj
```

Select the LumaLilt scheme and an installed iPhone simulator, then press Command-R.
Use Command-U to run tests. Choose your signing team before running on a physical device.

The project generator is optional, used only when source files are added or removed.
Run `python3 scripts/generate_project.py` and review its diff; it overwrites project metadata
and does not preserve manual project-only signing changes.

Copyright © 2026 Jonnathan R. MacKinnon. All rights reserved.
