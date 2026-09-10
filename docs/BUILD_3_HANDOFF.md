# LumaLilt build 3: physical-device feedback

Version 1.0, build 3. Keep the existing App Store Connect app and bundle ID
`com.mackinnontech.LumaLilt`. This update does not upload itself or change signing.

## What changed

- Stronger color separation is on by default for Tide, Dusk, and Ember. The original
  palettes remain available by switching this setting off. Number labels now use
  white text on an opaque dark badge. The destination preview also follows the
  number-label preference and is larger. Color alone is not required to solve.
- Tap to move is the default: select a tile, then tap a destination in its row or
  column. Its whole line shifts via the shortest cyclic route. It is not a free
  swap, so existing puzzle rules, hints and saved puzzles stay compatible.
  Dashed outlines indicate destinations. Tap the selected tile again to cancel,
  or use Choose another tile. A diagonal tap selects a different tile.
- The Arrows & swipe mode is still available. All four arrows are now labeled and
  placed in two rows so they are easier to use on an iPhone SE. Both directions
  were already implemented; the update makes their availability more explicit.
- Move counts are hidden by default during play, on the completion screen and in
  the share message. Settings can show them again. Counts are still recorded for
  existing history. One position shifted equals one move, including destination
  taps; undo restores the count. There is no move limit or score deduction.
- The daily button text is centered independently of the arrow. All primary
  buttons have horizontal padding and multiline centered text.

## Get the code on your Mac

Close Xcode first. Because your original checkout previously had a project-file
merge conflict and may contain local signing edits, the safest path is a fresh
sibling checkout. This leaves all existing files and signing edits untouched:

```bash
mkdir -p "$HOME/Developer"
git clone https://github.com/m4ckDev/LumaLilt.git "$HOME/Developer/LumaLilt-build3"
```

If that folder already exists, stop and inspect it; do not delete or overwrite it.
After cloning succeeds:

```bash
cd "$HOME/Developer/LumaLilt-build3"
git log -1 --oneline
bash scripts/validate_mac.sh
open LumaLilt.xcodeproj
```

The validation script uses full Xcode in /Applications or your Downloads folder.
To explicitly use your Downloads installation:

```bash
export DEVELOPER_DIR="$HOME/Downloads/Xcode.app/Contents/Developer"
bash scripts/validate_mac.sh
```

It validates metadata, runs the puzzle tests, discovers an available iPhone
simulator (preferring SE), and runs the app-hosted native tests. It prints short
progress messages and saves full logs under `build/validation`. It may leave a
simulator booted; it never erases or shuts down your devices.

For an existing **clean** checkout instead: run `git status --short`; only if it
is empty, run `git pull --ff-only origin main`. If Git refuses or shows conflicts,
stop. Do not use reset, checkout-theirs, or an automatic stash/rebase to overwrite
your Xcode settings. Do not rerun the project generator on your signed checkout;
the updated project is already committed.

## Xcode and physical-device check

1. Open the blue LumaLilt project, select the LumaLilt app target, then Signing &
   Capabilities. Select your **existing** team. Keep the bundle ID unchanged.
2. Confirm General shows Version 1.0 and Build 3. If build 3 is already uploaded,
   choose a higher unused build number before archiving.
3. Connect and unlock the iPhone SE. Trust the Mac and enable Developer Mode if
   Xcode requests it. Choose this physical phone in Xcode's destination selector.
4. Press Command-R to run. On a simulator, Command-U runs the native unit tests.
5. Check all palettes on 3×3, 4×4 and 5×5 boards. Toggle stronger colors and number
   labels. Verify readability, including the destination preview, at larger text.
6. In Tap to move mode, select a tile and a destination in the same row or column.
   Check left/right/up/down, wrapping at edges, cancel, diagonal reselection,
   and the Choose another tile button. A selection alone must not count a move.
7. Try Arrows & swipe mode in all four directions, including vertical swipes
   inside the scrolling page. Verify each gesture shifts only once.
8. Enable Show move count. A two-position destination shift counts two; each Undo
   reverses one shift. Turn the counter off and confirm no count on the game,
   completion screen, Home continue button, or shared result.
9. Test hints, completion, restarting and reopening the app with an unfinished
   puzzle. Existing progress and privacy-policy access must remain intact.
10. Check both Play today's puzzle and View today's puzzle button states. The
    label should stay centered, the arrow inset, and neither should clip on SE.
11. Repeat layout and interaction checks on a supported physical iPad, including
    portrait and landscape. Simulator tests are not physical-device QA.

## Archive and upload

Use either the Xcode menu or the local script after testing:

- Xcode: choose **Any iOS Device (arm64)**, then **Product > Archive**.
- Terminal, after choosing the team in Xcode:

```bash
bash scripts/archive_mac.sh
```

The script reads your existing Release signing settings, creates a new local
archive without overwriting older archives, and opens it in Organizer. If signing
fails, inspect the error in Xcode; the script does not create or change profiles.

In Organizer choose the new archive > Distribute App > App Store Connect and
complete the upload flow. Do not select TestFlight Internal Only for a build you
intend to submit for App Store review. Wait for processing in App Store Connect.

## Replace the submitted build

1. Add the processed build to your internal TestFlight group and update LumaLilt
   on the phone. Confirm TestFlight shows the new build number.
2. Test the uploaded build again, then record a new physical-device walkthrough
   of this build. Do not reuse a build 2 recording to demonstrate build 3.
3. Open App Store Connect > LumaLilt > Distribution > version 1.0.
4. If the submission is locked in Waiting for Review or In Review, remove that
   submission from review first. If already editable following rejection, do not
   remove anything unnecessarily.
5. In Build, remove the old build's **association with this version**, select
   build 3 (or the higher number actually uploaded), and Save. This does not
   delete the older build from TestFlight or erase your users' data.
6. Complete any export-compliance prompts accurately. Update review Notes and
   the review conversation with the correct build, testing details, fresh video,
   and Apple's six requested answers. Describe only checks actually completed.
7. Update App Store screenshots if they no longer represent this UI. Complete
   Add for Review and the final submission action shown by App Store Connect.

## Verification boundaries

Automated coverage includes shortest-path destination shifts for all supported
board sizes, both directions and wraparound, invalid selections, move counting,
undo, JSON round trips, hint route validity, palette ranges/separation, and the
existing puzzle tests. Numeric color separation is not a substitute for visual
accessibility testing. GitHub's macOS CI builds SwiftUI and executes native tests;
human physical-device checks and the new review recording remain required.
