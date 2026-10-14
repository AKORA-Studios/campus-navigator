# Campus Navigator Release Candidate QA Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox syntax for tracking.

**Goal:** Prepare an isolated, reviewable release candidate that integrates completed Campus Map, Campus Identity, and Settings work, then document its regression status and APK.

**Architecture:** Use the latest UI refinement commit as the integration base because it descends from the campus-map and search/favorites work and already includes the Settings and Campus Identity implementation. Compare the parallel settings branch for unique changes, then apply only nonduplicated completed work and targeted QA fixes.

**Tech Stack:** Flutter, Dart, Flutter widget/integration tests, Android Gradle APK, Android emulator.

**Spec:** User request in the 2026-10-14 task, “Campus Navigator – Release-Kandidat und Qualitätssicherung”.

## Global Constraints

- Preserve all existing working features and architectural floor plan accuracy.
- Do not modify the stable `master` branch.
- Do not modify the floorplan renderer without a concrete reproduced defect.
- Keep integration changes isolated and small; retain the existing architecture.
- Report untested functionality, failures, and visual issues explicitly.
- Wait for user approval before any final integration into the stable branch.

## Review Focus

- Empty and failed API responses: verify the UI remains usable and communicates the state.
- Returning from external Google Maps: verify the app resumes with the selected location intact.
- Rotation, large text, and narrow layouts: verify no overflow or lost navigation state.
- Persisted settings, favorites, and history: verify expected values survive app restart and cache clearing.
- Room highlighting and floor transitions: verify focus remains visible without changing renderer geometry.

## File Map

- Existing `lib/` and `test/`: application behavior and focused regression coverage; only modify for reproduced defects.
- Existing `docs/ui-evidence/`, `docs/settings-evidence/`, and workspace evidence: visual references and prior QA evidence.
- `docs/superpowers/plans/2026-10-14-release-candidate-qa.md`: integration and QA checklist.
- `docs/release-candidate-qa.md`: final run results, limitations, visual notes, and next steps.
- `build/app/outputs/flutter-apk/app-debug.apk`: installable debug APK artifact.

## Integration and QA Tasks

### Task 1: Preserve and integrate completed changes

- [x] Create a safety tag at the latest documented known-good candidate commit.
- [x] Create an isolated release QA branch from `feature/ui-refinement`; confirm it includes `feature/campus-map` and `feature/search-and-favorites` ancestry.
- [x] Merge `feature/settings` into the release QA branch with a merge commit; preserve the consolidated UI implementation and record any conflict resolutions.
- [x] Include unique settings evidence from `feature/settings` while avoiding duplicate runtime code.
- [x] Keep indoor-navigation experiment files out of scope.

### Task 2: Establish automated regression status

- [x] Run `flutter analyze` and `flutter test` from the integration worktree.
- [x] Review existing tests for search, result selection, favorites/history, map, floors, identity, settings, persistence, and localization.
- [x] Add focused widget coverage for rotated building detail actions.
- [x] Run the focused widget test, then the relevant full suite.

### Task 3: Visual and device QA

- [x] Review available reference screenshots for phone/tablet and light/dark states.
- [x] Check room labels, contrast, highlighted rooms, layout overflow, and minimum touch targets.
- [x] Exercise search-to-room, favorites/history, building/map/floor selection, navigation handoff and return, settings persistence, back navigation, rotation, and large text in the emulator where supported.
- [x] Build an Android debug APK and record its exact path and verification status.

### Task 4: Release candidate report

- [x] Record commands and outcomes, remaining defects, untested paths, visual findings, and recommended next steps in `docs/release-candidate-qa.md`.
- [x] Create an annotated rollback tag `v0.1.0-rc1` on the verified candidate commit.
- [x] Confirm the stable `master` ref remains unchanged and the release QA worktree is clean apart from intentional candidate changes.
- [x] Stop before merging or transferring changes to `master`; user approval is required for that final step.
