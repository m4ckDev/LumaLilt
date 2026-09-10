# Build 4 verification

## Automated gates

- Metadata checker: project references, shared scheme, three targets, RGB 1024 icon, privacy manifest.
- Production Swift core: 13 tests, including 600 seeded puzzles, every possible swap pair on all
  board sizes, hints that strictly improve correctness, undo, reset, save migration and malformed saves.
- Native app compilation and native XCTest on an available iPhone simulator.
- Three XCUITest flows: guided practice, diagonal swap + one Undo, hint preservation + target sheet.
- CI uploads logs and xcresult bundles (including screenshots) for inspection.

The GitHub workflow result is the authority for whether these gates passed for a particular commit.
No script claims human enjoyment or device performance based on functional test success.

## Physical-device release checks

1. Update an existing TestFlight installation; confirm Settings shows the new build and saved progress remains.
2. Complete or skip guided practice, then replay it through Help.
3. Test 3×3, 4×4 and 5×5 boards. Swap horizontal, vertical and diagonal pairs; check all other positions stay put.
4. Cancel selection by tapping the selected tile. One Undo must restore a complete swap and its move count.
5. Use hints: every hint adds at least one correct tile and preserves previously correct positions.
6. Solve a board; confirm completion, one history record, sharing and a fresh puzzle.
7. Check the pinned target and expanded pattern on iPhone SE, iPad portrait/landscape and larger text sizes.
8. Check all palettes, optional numbers, optional counter, haptics, VoiceOver and Reduce Motion.
9. Check Reset, backgrounding, force-close/reopen, offline play and UTC daily rollover.
10. Watch the swap animation on a device; assess whether it clearly shows two tiles travelling.
11. Have a first-time player try a puzzle without coaching and note confusion, accidental actions and interest in another puzzle.
12. Record the actual release build on a physical device for Apple's information request and update screenshots/listing text.

Mac Catalyst remains an optional target and needs its own native run before any Mac distribution claim.
