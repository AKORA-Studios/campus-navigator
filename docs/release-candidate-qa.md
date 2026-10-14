# Campus Navigator – Release Candidate QA

**Release version:** `1.3.0+5` · **GitHub tag:** `v1.3.0` · **Branch:** `release/qa-2026-10-14` · **Test date:** 2026-10-14
**Stable branch:** `master` remained at `0441326300600ceff155dad0e1b0a89b2d4f3710`.

## Integration record

- `feature/campus-map` (`d5609b0`) and `feature/search-and-favorites` (`aab8dba`) are ancestors of the candidate. They supply the campus map, building search, Google Maps handoff, room search, favorites, and history.
- `feature/ui-refinement` (`858808e`) is the candidate base and contains the completed Campus Identity/UI work. The rollback point `backup/last-known-good-2026-10-14` preserves that verified commit.
- `feature/settings` (`83f3e96`) was merged with a merge commit. Its runtime settings behavior was already consolidated on the UI branch; the merge carries the branch history and its unique Android settings evidence without duplicating runtime code.
- The only merge conflict was add/add in `docs/settings.md`. The resolution retained the consolidated settings documentation and added references to the settings branch's evidence screenshots.
- No indoor-navigation experiment files were included. No application source or floorplan renderer change was needed for this QA pass.

## Automated checks

Flutter SDK 3.24.5 / Dart 3.5.4 was used.

The release version was advanced from `1.2.1+4` to `1.3.0+5` before the final verification and APK build.

| Check | Result |
|---|---|
| `flutter analyze --no-pub` | No analyzer errors or warnings. It reports 36 `info` lints (existing naming, style, and deprecation notices) and exits with code 1 because infos are counted as findings. |
| `flutter test --no-pub -r expanded` | **153 passed, 26 skipped, 0 failed.** The private real-floor-plan cases require local fixture configuration (`PRIVATE_PLAN_DIR` / `REAL_PLAN_DIR`) and were not enabled. |
| `flutter build apk --debug` | **Succeeded.** Installable debug APK was built. |
| Focused rotated-layout suite | **10 passed**, including the new test that scrolls a selected building's details to expose the floor and route actions in landscape. |

The test process also prints `Warning: No Tables in Room OccupancyTable` for an empty occupancy fixture; it does not fail a test.

## Emulator and visual checks

Manual interaction was performed in the Android 14 / API 34 phone emulator (1080×1920 at 420 dpi), including landscape rotation.

- Room search for `BEY 318` opened the expected BEY 318 floor-03 plan. The selected room highlight is visible and adjacent labels remain distinguishable.
- Building search selected APB, opened its floor-plan flow, and supported changing floors from 03 to 02.
- Favorites and recent history appeared after saving a room.
- Google Maps opened walking directions for the selected building. Returning required backing out of the directions screen and then the Maps home screen; Campus Navigator resumed with the selected building retained.
- Settings theme selection applied immediately and remained selected after an app restart.
- Light and dark map/settings screens were inspected. Map controls met the 48 dp target measured on the emulator. No overflow or reproducible crash was observed.
- The landscape building-details panel scrolls vertically; the floor and navigation actions are available after a swipe. They are below the initial visible portion, so their discoverability in landscape can be improved later.
- Existing tablet and alternate-theme screenshots were reviewed, and tablet/narrow-phone/text-scaling layouts are covered by widget tests. A live tablet emulator pass was not performed.

Evidence screenshots are in [`docs/release-candidate-evidence/`](release-candidate-evidence/). Selected reference images: [BEY 318 highlighted in dark mode](release-candidate-evidence/phone-room-detail.png), [dark campus map](release-candidate-evidence/phone-map-dark.png), [landscape details after scroll](release-candidate-evidence/phone-map-landscape-scrolled.png), and [settings after restart](settings-evidence/settings-after-restart.png).

## Remaining limits and observations

- No reproducible functional defect was found during this pass; the floorplan renderer was left unchanged.
- The 36 analyzer infos remain, so `flutter analyze` is not currently a zero-exit check. They are mostly existing identifier/style notices and deprecated Flutter state APIs; they should be addressed in a separately scoped cleanup.
- 26 tests remain skipped without the private floor-plan fixture configuration.
- Network failure, empty responses, retry, and no-result states are covered by automated tests with controlled responses. A live backend outage was not induced on the emulator.
- A physical device, live tablet emulator, iOS build, and signed release/store build were not tested. The delivered APK is a debug build for QA installation, not a production-signed artifact.
- Google Maps handoff/return was manually checked on an emulator with Google Maps installed; behavior on devices without a compatible navigation app is covered by widget tests, not a second physical device.

## Artifact and rollback

- APK: [`build/app/outputs/flutter-apk/app-debug.apk`](../build/app/outputs/flutter-apk/app-debug.apk)
- SHA-256: `9C7784952A300C100B2459A1D1013F6ED0A123CFED1872C12808A1A1BB56E9B9`
- The annotated tag `v0.1.0-rc1` preserves the initial QA candidate. The release tag `v1.3.0` identifies the versioned release commit. `backup/last-known-good-2026-10-14` identifies the pre-integration known-good UI commit.
- Candidate changes remain isolated on `release/qa-2026-10-14`. No merge, cherry-pick, or ref update was made on `master`; final adoption is waiting for user approval.

## Recommended next steps

1. Decide whether to clean up the 36 analyzer infos in a separate change.
2. Run the 26 private floor-plan cases when fixture access is available, then do a live tablet pass.
3. Consider a landscape layout adjustment that brings building actions into view sooner without changing floorplan rendering.
4. After approval, merge the candidate to the stable branch and produce a signed release artifact through the normal release process.
