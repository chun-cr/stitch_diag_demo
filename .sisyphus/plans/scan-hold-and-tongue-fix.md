# Scan Hold And Tongue Fix Plan

## Goal

Fix three related issues with the smallest safe change set:

1. tongue scan can detect mouth presence but still misses real tongue-out states too often
2. palm scan should give an obvious tongue-like bubble + 2-second hold progress experience
3. face scan should stop using numeric countdown and instead use a tongue-like 2-second hold progress interaction

## Confirmed Repository Facts

- `lib/features/scan/presentation/services/tongue_scan_status_bridge.dart` currently gates `readyToScan` at `0.26`.
- `ios/Runner/TongueDetectionEvaluator.swift` and `android/app/src/main/kotlin/com/example/stitch_diag_demo/TongueDetectionUtils.kt` currently use `0.2` as the tongue-out score threshold and still allow a geometry fallback in `tongueDetected`.
- `lib/features/scan/presentation/pages/tongue_scan_page.dart` already implements the target interaction model: frame-level bubble prompt plus a visible 2-second progress bar driven by hold state.
- `lib/features/scan/presentation/pages/palm_scan_page.dart` already has a frame-level status pill and progress bar, but the current presentation is still perceived as lacking clear interaction.
- `lib/features/scan/presentation/pages/face_scan_page.dart` still uses a numeric `_CountdownPill` rather than a progress hold pattern.

## Ranked Root Causes

1. **Tongue false-negative band**: the Dart bridge threshold (`0.26`) is stricter than current native-positive detection (`0.2`), so valid tongue-out states in the `0.20-0.25` band never become ready.
2. **Palm interaction perception gap**: palm technically has hold UI, but the bubble and progress treatment are not as clearly unified as tongue scan, so users do not perceive the hold start strongly enough.
3. **Face interaction inconsistency**: face scan uses a separate numeric countdown model, so it feels different from tongue/palm and does not provide the same “hold steady now” feedback.

## Minimal-Diff Implementation Plan

### Step 1 — Lock behavior with tests first
- Update `test/features/scan/tongue_scan_status_bridge_test.dart` so the ready boundary explicitly reflects the native-positive band:
  - fallback-only (`tongueDetected=true`, low score) must remain not ready
  - `tongueOutScore >= 0.20` should become ready when mouth landmarks are present

### Step 2 — Fix tongue ready threshold in the Dart bridge
- Change `TongueScanStatus._tongueOutReadyThreshold` from `0.26` to `0.20`.
- Keep `readyToScan` strict: it must still require `mouthPresent && tongueDetected && tongueOutScore >= threshold`, so fallback-only geometry does not bypass the score gate.

### Step 3 — Make palm hold feedback unmistakable
- Keep palm detection/hold logic and navigation intact.
- Adjust the frame-level feedback presentation in `palm_scan_page.dart` so the hold bubble and 2-second progress feel visually tied together like the tongue page.
- Reuse existing localization strings such as `scanPalmReadyHold`; do not add new copy unless absolutely necessary.

### Step 4 — Replace face numeric countdown with 2-second hold progress
- Keep face tap-to-start flow intact.
- Replace the numeric `_CountdownPill` model with a progress-based hold interaction that mirrors tongue/palm.
- Prefer reusing the existing frame-level bubble plus a visible progress bar rather than adding a new overlay or a new interaction surface.

### Step 5 — Verify on changed scope only
- Run focused tongue tests first.
- Run analyze on touched scan files.
- If lightweight helper tests are practical for face/palm hold semantics, add them; otherwise verify UI structure and logic through changed-file analysis and runtime-safe code review.

## Files Likely To Change

- `lib/features/scan/presentation/services/tongue_scan_status_bridge.dart`
- `test/features/scan/tongue_scan_status_bridge_test.dart`
- `lib/features/scan/presentation/pages/palm_scan_page.dart`
- `lib/features/scan/presentation/pages/face_scan_page.dart`
- ARB files only if new visible text becomes unavoidable

## Verification

- `flutter test test/features/scan/tongue_scan_status_bridge_test.dart`
- `flutter analyze lib/features/scan/presentation/services/tongue_scan_status_bridge.dart lib/features/scan/presentation/pages/palm_scan_page.dart lib/features/scan/presentation/pages/face_scan_page.dart test/features/scan/tongue_scan_status_bridge_test.dart`
- `lsp_diagnostics` on changed Dart files

## Runtime QA Scenarios

### Scenario 1 — Tongue positive band reaches ready state
- Tool: `flutter test` + runtime/manual app check
- Show a real tongue-out that produces a score in the native-positive band near the threshold.
- Expected: tongue scan enters hold state instead of staying stuck in mouth-only detection.

### Scenario 2 — Fallback-only mouth geometry does not start hold
- Tool: `flutter test` + runtime/manual app check
- Present mouth-open / geometry-only state without genuine tongue-out score.
- Expected: mouth detection remains visible, but hold progress does not begin.

### Scenario 3 — Palm hold is obvious
- Tool: runtime/manual app check
- Present a valid palm until ready state begins.
- Expected: a clear bubble prompt plus a visible 2-second progress indicator appears near the frame.

### Scenario 4 — Face uses progress instead of numeric countdown
- Tool: runtime/manual app check
- Align the face, tap start, and hold steady.
- Expected: no numeric countdown bubble; a tongue-like hold progress interaction is shown instead.

## Task-Level QA

### Task 1 — Lock regression expectations
- Tool: `flutter test test/features/scan/tongue_scan_status_bridge_test.dart`
- Steps: run existing/updated tongue bridge tests before production code changes
- Expected: threshold-boundary regression fails first or clearly captures intended behavior before the fix

### Task 2 — Align tongue ready threshold
- Tool: `flutter test test/features/scan/tongue_scan_status_bridge_test.dart`
- Steps: rerun tongue bridge test suite after threshold change
- Expected: low-score fallback-only cases stay not-ready; `0.20+` ready band turns green

### Task 3 — Make palm hold feedback obvious
- Tool: `flutter analyze lib/features/scan/presentation/pages/palm_scan_page.dart` + runtime/manual app check
- Steps: verify page compiles cleanly, then present a valid palm and watch frame-level bubble/progress behavior
- Expected: a visible hold bubble plus 2-second progress appears as soon as hold begins, with no logic regression in completion flow

### Task 4 — Replace face numeric countdown
- Tool: `flutter analyze lib/features/scan/presentation/pages/face_scan_page.dart` + runtime/manual app check
- Steps: verify page compiles cleanly, then start face scan and watch the hold interaction
- Expected: numeric countdown disappears; progress-based hold feedback appears and still leads to tongue page navigation

### Task 5 — Final verification
- Tool: `lsp_diagnostics`, `flutter test`, `flutter analyze`, runtime/manual app check, Oracle review
- Steps: run changed-scope diagnostics/tests/analyze, manually inspect tongue/palm/face flows, then perform read-only Oracle review
- Expected: changed files are clean, targeted tests pass, and runtime behavior matches the requested interaction model
