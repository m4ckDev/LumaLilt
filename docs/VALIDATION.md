# Validation and first native run

Generation environment: Linux, September 9, 2026. Swift and Xcode are not installed here.

Checks performed:

- Python project generator executes and produces deterministic metadata.
- Every app Swift source is referenced by the Xcode project.
- Project object references and shared scheme target references resolve.
- App and hosted XCTest targets are present.
- JSON asset catalogs and XML privacy manifest parse.
- Included icon is an opaque RGB 1024×1024 PNG rendered from the repository's vector tile mark.
- Eight Swift test cases are included and referenced by both the Xcode target and Swift package.
- Source review of rotation, inverse route, deterministic UTC generation, undo, assistance tracking,
  completion deduplication, and atomic save handling completed.

Not executed here:

- Swift compilation or the eight XCTest cases.
- Xcode simulator build, physical-device run, or Mac Catalyst build.
- Visual verification of the actual SwiftUI screens, VoiceOver, Dynamic Type, or gestures.
- Signing, TestFlight, App Store name reservation, or publication.

These are meaningful outstanding checks. Do not interpret structural validation as a successful native build.

## On your Mac

1. Open `LumaLilt.xcodeproj`, select LumaLilt and an installed iPhone simulator.
2. Command-U: all eight tests should pass. The solvability test checks 600 seeds across three sizes.
3. Command-R: verify onboarding appears once and How to Play remains available afterward.
4. Start every difficulty. Check row and column wraparound by swipe and by arrows.
5. Make moves, undo, use a hint, undo it, restart. Verify the puzzle stays marked assisted.
6. Finish a puzzle by repeated hints. Check the collection increments exactly once and controls lock.
7. Start another board, make moves, background/terminate/reopen. Confirm board, moves, hints, and undo persist.
8. Complete Daily Lilt, reopen it, and verify no duplicate completion is recorded.
9. Change the simulator date past midnight UTC, background/foreground, and confirm a fresh daily board appears.
10. Replace an unfinished free-play puzzle and verify a confirmation appears. Confirm daily progress is separate.
11. Check every palette and the number toggle. Numbers must retain readable contrast.
12. Enable VoiceOver. Select a tile and operate the four named arrow buttons. Check completion announcements
    and revise accessibility if needed after testing. Test large accessibility text and Reduce Motion.
13. Test a small iPhone, iPad portrait/landscape, and My Mac (Mac Catalyst), including narrow windows.
14. Share a completed result and cancel the share sheet. Confirm no action happens without choosing a destination.
15. Enable airplane mode and play all modes. Confirm no network access is needed.
16. Reset all progress in Settings, cancel once, then confirm. Appearance preferences should remain.

Suggested build command (no signing required):

```bash
xcodebuild -project LumaLilt.xcodeproj -scheme LumaLilt \
  -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```

Standalone production-engine tests:

```bash
swift test
```
