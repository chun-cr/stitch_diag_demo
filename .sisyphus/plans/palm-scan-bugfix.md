# Palm Scan Feedback Bugfix Plan

## Goal

Restore visible palm-scan feedback on the Flutter palm scan page and make the page explicitly communicate when detection has started, without broad refactors or native threshold changes.

## Repository Facts

- `lib/features/scan/presentation/pages/palm_scan_page.dart` auto-requests camera permission and immediately starts `gesture/startDetection` on success.
- The palm page currently has no explicit "detection started / waiting for hand" state, so the user can enter a silent auto-detect phase.
- Palm result UI is currently split across `_StatusPill`, `_PalmDirectionPill`, progress bar, and `HandLandmarkOverlay`.
- `HandLandmarkOverlay` only paints when it has at least 21 landmarks, but the page passes whatever the bridge reports without an extra validity guard.
- Existing related patterns live in `face_scan_page.dart` and `tongue_scan_page.dart`: both use richer state feedback and clearly distinguish waiting/detected/hold states.

## Most Likely Root Causes (ranked)

1. **Missing explicit startup feedback in palm page UI**
   - Evidence: palm page immediately starts monitoring but `_statusText()` jumps from waiting-permission to alignment hints without a dedicated "detection has started" state.
   - User impact: feels like the page is not responding even when detection has already begun.

2. **Palm result visibility depends on sparse/implicit conditions**
   - Evidence: the page derives visible state from several booleans (`_handPresent`, `_readyToScan`, `_handStraight`, `_gestureName`, `_palmHint`) and can present low-confidence/noisy transitions with no clear top-level feedback.
   - User impact: intermittent hand presence may not feel like an acknowledged detection state.

3. **Overlay should only render with valid drawable input**
   - Evidence: `HandLandmarkOverlay` already exits for `<21` points, but the page still hands it raw bridge data regardless of image-size validity.
   - User impact: result feedback may appear inconsistent even when event flow is active.

## Minimal-Diff Implementation Plan

### Step 1 — Make monitoring state explicit in `palm_scan_page.dart`
- Add lightweight page state such as:
  - `_isMonitoring`
  - `_hasDetectionFeedback`
  - `_cameraReady` only if needed for minimal UX continuity
- Set `_isMonitoring = true` once permission is granted and monitoring is started.
- Use this to expose a clear "detecting / waiting for palm" state before any hand is present.

### Step 2 — Refine palm status semantics in `palm_scan_page.dart`
- Add one explicit status branch for:
  - waiting for permission
  - starting / detecting
  - hand detected but not ready
  - open palm detected but needs straightening
  - ready to hold
  - completed
- Keep existing gesture and direction hints, but ensure a user always sees an actionable message when monitoring is active.

### Step 3 — Improve visible interaction feedback in the bottom area
- Reuse current visual language rather than redesigning:
  - show a subtle active-state chip / banner / helper row once monitoring starts
  - keep status copy concise and consistent with face/tongue pages
- Avoid changing the overall layout structure.

### Step 4 — Guard overlay rendering more strictly
- Only mount `HandLandmarkOverlay` when landmarks are drawable and image size is valid.
- This should be a local page-level guard first; avoid changing overlay internals unless clearly necessary.

### Step 5 — Localize any new user-visible text
- Update all four ARB files:
  - `lib/l10n/app_zh.arb`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_ja.arb`
  - `lib/l10n/app_ko.arb`
- Reuse existing scan wording where possible; add new keys only for genuinely new states.

### Step 6 — Add focused regression coverage
- Add or update a focused test for the new palm feedback semantics.
- Preferred scope: pure status derivation or bridge-adjacent state semantics, not a heavy widget test unless needed.

## Files To Change

- `lib/features/scan/presentation/pages/palm_scan_page.dart`
- `lib/features/scan/presentation/widgets/hand_landmark_overlay.dart` (only if page-level guard is insufficient)
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_ko.arb`
- `test/features/scan/palm_scan_status_bridge_test.dart` or another focused nearby test file

## TDD-Oriented Execution

1. Define the intended feedback states first.
2. Add/update a focused test for the new semantics.
3. Implement the minimal page logic and ARB changes.
4. Regenerate l10n and run diagnostics/tests.

## Verification Checklist

- `flutter gen-l10n`
- `lsp_diagnostics` on all changed Dart files
- `flutter analyze` on changed files and affected l10n/generated scope
- Focused `flutter test` for palm scan related tests

## Runtime QA Scenarios

### Scenario 1 — Monitoring started, no hand yet
- Tool: app run / manual runtime check
- Steps:
  1. Open the palm scan page.
  2. Grant camera permission if prompted.
  3. Keep the hand out of frame.
- Expected result:
  - The page shows a visible "detecting / waiting for palm" prompt.
  - The page does not look idle or silent after monitoring begins.

### Scenario 2 — Palm enters frame but is not yet ready
- Tool: app run / manual runtime check
- Steps:
  1. Show a hand that is partially misaligned, too near/far, or not fully straight.
  2. Observe the status region.
- Expected result:
  - The page visibly acknowledges palm detection or guidance.
  - The user sees actionable feedback such as align/move/straighten rather than a silent state.

### Scenario 3 — Palm becomes ready
- Tool: app run / manual runtime check
- Steps:
  1. Present an open, straight palm inside the frame.
  2. Hold it steady.
- Expected result:
  - The page advances to the detected / hold feedback state.
  - The hold progress becomes visible and completion still works.

### Scenario 4 — Invalid drawable overlay input
- Tool: focused test and/or guarded code path review
- Steps:
  1. Feed incomplete landmarks or zero/invalid image size through the relevant state path.
  2. Observe overlay mounting behavior.
- Expected result:
  - The overlay stays hidden.
  - Monitoring / status feedback remains visible so the page still feels responsive.

## Atomic Commit Strategy

1. `fix`: restore visible palm scan feedback and explicit detecting state
2. `test`: add/update focused palm scan feedback regression coverage
