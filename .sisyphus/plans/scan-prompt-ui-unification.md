# Scan Prompt UI Unification Plan

## Goal

Unify prompt presentation across the scan flow with minimal Flutter-only UI changes:

- replace the face scan full-screen countdown overlay with a compact tongue-style in-frame bubble prompt
- remove the palm scan bottom large feedback card and rely on tongue-style small bubble feedback near the scan frame
- keep tongue scan as the visual baseline
- avoid changing scan readiness or navigation logic

## Repository Facts

- `lib/features/scan/presentation/pages/tongue_scan_page.dart` already provides the target interaction pattern: frame-adjacent `_StatusPill` / `_TongueDirectionPill` plus optional progress bar.
- `lib/features/scan/presentation/pages/face_scan_page.dart` currently uses a full-screen dark overlay with large countdown text while `_isScanning && _countdown > 0`.
- `lib/features/scan/presentation/pages/face_scan_page.dart` already has a frame-adjacent `_StatusPill` / `_DirectionPill`, so the countdown can be moved into that presentation layer instead of a new global overlay.
- `lib/features/scan/presentation/pages/palm_scan_page.dart` already has frame-adjacent `_StatusPill` / `_PalmDirectionPill`, but also adds a bottom `_LiveFeedbackCard`, creating duplicated feedback.
- Existing localization keys appear sufficient for this UI-only change (`scanKeepStill`, `scanScanning`, `scanPalmHoldButton`, etc.).

## Minimal-Diff Plan

### Step 1 — Face scan: replace full-screen overlay with a compact countdown pill
- Remove the full-screen overlay block rendered when `_isScanning && _countdown > 0`.
- Extend the existing frame-level status area so that when `_isScanning` is active it shows a countdown bubble instead of the regular `_StatusPill` / `_DirectionPill`.
- Keep current countdown state (`_countdown`) and scan flow logic unchanged.
- Reuse existing localized copy such as `scanKeepStill`; only add ARB keys if layout/content truly requires new wording.

### Step 2 — Face scan: keep bottom card behavior stable
- Keep the start button fade/disable behavior during scanning.
- Do not redesign the bottom card or countdown logic itself; only change presentation.

### Step 3 — Palm scan: remove duplicated large feedback card
- Delete `_LiveFeedbackCard` usage from the bottom card.
- Preserve the existing frame-level `_StatusPill` / `_PalmDirectionPill` as the primary feedback surface, since it already matches the tongue-page interaction model.
- Keep the dynamic bottom button label if still useful, but do not leave a second large text explanation block.

### Step 4 — Palm scan: clean up unused component code
- Remove `_LiveFeedbackCard` if it becomes unused.
- Keep feedback-stage logic if still needed for button labels/status semantics; do not refactor the state machine unless necessary.

### Step 5 — Tongue scan: leave structure unchanged
- Only touch `tongue_scan_page.dart` if a tiny shared-style extraction is clearly beneficial.
- Prefer duplication over abstraction unless a shared helper produces an obviously smaller and clearer diff.

## Files Likely To Change

- `lib/features/scan/presentation/pages/face_scan_page.dart`
- `lib/features/scan/presentation/pages/palm_scan_page.dart`
- `lib/l10n/app_zh.arb` / `app_en.arb` / `app_ja.arb` / `app_ko.arb` only if new copy is truly required
- related focused tests only if prompt semantics become testable and worth locking down

## Verification

- `lsp_diagnostics` on changed Dart files
- `flutter analyze` on changed scan page files
- `flutter test` on any affected focused tests
- runtime/manual check recommended for face scan countdown presentation and palm prompt visibility

## Runtime QA Scenarios

### Scenario 1 — Face idle state still works
- Tool: app run / manual runtime check
- Steps:
  1. Open the face scan page.
  2. Observe the frame-adjacent prompt before scanning starts.
  3. Move the face in and out of frame.
- Expected result:
  - The regular status pill / direction pill still switches between permission, align, and detected-ready states.
  - No countdown bubble is shown before scan start.

### Scenario 2 — Face countdown becomes a compact bubble
- Tool: app run / manual runtime check
- Steps:
  1. On the face scan page, align the face and tap the start button.
  2. Watch the UI during `_countdown`.
  3. Wait until automatic navigation to the tongue scan page begins.
- Expected result:
  - The old full-screen dark overlay no longer appears.
  - A compact bubble near the frame shows countdown + keep-still feedback.
  - `_countdown` still decrements and navigation timing is unchanged.

### Scenario 3 — Palm removes only duplicated large feedback
- Tool: app run / manual runtime check
- Steps:
  1. Open the palm scan page.
  2. Observe the bottom card before and during scanning.
  3. Compare the frame-level prompt and bottom section while the hand is absent.
- Expected result:
  - The bottom large `_LiveFeedbackCard` is gone.
  - The frame-adjacent bubble remains the primary prompt surface.
  - The bottom button area remains intact and usable as before.

### Scenario 4 — Palm ready and completion flow stays intact
- Tool: app run / manual runtime check
- Steps:
  1. Present a valid palm until the hold flow starts.
  2. Watch the frame-level prompt and progress bar.
  3. Let the scan complete.
- Expected result:
  - The frame-level bubble still reflects scanning / hold / completed states.
  - The progress bar still advances correctly.
  - Completion and report navigation behavior remain unchanged.
