# LumaLilt 1.0 (4): pair swaps

## Get the code onto your Mac

Quit the older LumaLilt Xcode window. In Terminal:

```bash
mkdir -p "$HOME/Developer"
git clone https://github.com/m4ckDev/LumaLilt.git "$HOME/Developer/LumaLilt-build4"
cd "$HOME/Developer/LumaLilt-build4"
open LumaLilt.xcodeproj
```

If clone reports that the destination exists, stop; do not delete it or overwrite its changes.
A fresh sibling folder avoids the signing/merge conflict from the previous checkout.
Existing local folders and installed app progress remain untouched by cloning.

## Run in Xcode

1. Select the LumaLilt project, then the LumaLilt app target.
2. Signing & Capabilities: select your existing developer team.
3. Keep the bundle identifier `com.mackinnontech.LumaLilt`.
4. General: verify Version 1.0, Build 4. If 4 was already uploaded, use the next unused build number.
5. Choose your connected iPhone in the destination menu and press Command-R.
6. Complete the two-swap practice. Confirm other tiles stay still.
7. Test swaps, Undo, hints, Reset, target enlargement, colors, saved progress and completed puzzles.

For automated checks on your Mac:

```bash
cd "$HOME/Developer/LumaLilt-build4"
bash scripts/validate_mac.sh
```

The script finds full Xcode in Applications or Downloads unless DEVELOPER_DIR is already set,
discovers an available simulator, and runs the engine and UI tests. Logs and result bundles are
under `build/validation`. It may boot a simulator; it does not erase simulators or change signing.
Command-U in Xcode with a simulator destination runs the same native test targets.

## Archive and upload

```bash
cd "$HOME/Developer/LumaLilt-build4"
bash scripts/archive_mac.sh
```

1. Organizer opens the newly created archive. Verify 1.0 (4), or your chosen higher build.
2. Distribute App → App Store Connect → continue through validation and upload.
3. Use normal App Store distribution, not TestFlight Internal Only.
4. Wait for processing in App Store Connect. Assign the new build to your internal TestFlight group.
5. Update LumaLilt through TestFlight on the physical iPhone. Settings shows the installed build.

The script creates a local archive only. Upload requires your signed-in Xcode session on your Mac.
No remote session from the coding environment controls your Mac or its Xcode installation.

## Replace the attached App Store build

1. App Store Connect → LumaLilt → Distribution → iOS version 1.0.
2. If the version is locked by an active review submission, remove that submission from review
   before editing. If it is already editable after an information request/rejection, edit it directly.
3. In Build, remove the previous build's association with this version, then select the processed
   new build and Save. Do not delete the old app record or expire the old TestFlight build merely
   to replace this association.
4. Replace screenshots or description text that still shows row/column controls. Use the updated
   `docs/APP_STORE.md` copy. The subtitle is now “Calm colors. Simple swaps.”
5. Record the NEW TestFlight build on the physical iPhone, beginning with app launch and showing
   practice or its dismissal, creating/solving a puzzle, swaps, Undo, hints and the daily puzzle.
6. Attach that recording to the App Review conversation. Include Apple's six requested information
   points, and copy them into App Review Information → Notes. State only tests actually performed.
7. Save, Add for Review and complete the final submission step. Upload alone does not resubmit it.

## What changed and what to test

- Any two tiles swap, including diagonals. No row/column shifting or swipe controls remain.
- One Undo reverses one swap while the puzzle is active; completed boards remain locked.
- Hints move a misplaced tile home while preserving every correct tile.
- Target is pinned above the scrolling game; tap to view a large pattern.
- Position-based animation replaces color-only transitions; Reduce Motion turns it off.
- New and existing users see the new guided practice once. Help can replay it.
- Stronger colors, readable number badges and the centered Daily CTA from build 3 are retained.
- Move count stays optional and off by default. Hints are recorded for history, with gentle completion copy.
- Builds 1–3 saves are migrated on load without replacing the board, history, counters or undo snapshots.
  Migrated daily boards may differ from fresh installations until the next UTC rollover.
- No changes to pricing, privacy services, account requirements, app bundle ID or signing team.

Physical checks: iPhone SE, 3×3/4×4/5×5, all three palettes, numbers off/on, larger text, VoiceOver,
Reduce Motion, iPad portrait/landscape, restart and background/force-close/reopen. Check that the
visible animation actually feels clear and comfortable. Automated tests do not establish enjoyment.
