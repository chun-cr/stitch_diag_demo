# Google Pay Abstraction Layer Plan

## Goal

Add a minimal Flutter-side Google Pay abstraction layer for the report checkout flow without real payment integration yet.

## Confirmed repository facts

- `lib/features/report/presentation/pages/report_checkout_page.dart` already has Google Pay placeholder UI and copy.
- `lib/features/report/application/mock_product_checkout.dart` currently only returns `OrderPreview`; it does not yet model a checkout session.
- `lib/features/report/application/report_unlock_service.dart` shows a local application-service pattern: immutable state model + service class with explicit public API.
- `pubspec.yaml` currently has no Google Pay specific Flutter dependency.
- `docs/2026-04-01_GooglePay_无后端阶段实施清单.md` already defines the intended no-backend phase shape: `CheckoutSession`, `PaymentMethod`, `PaymentResult`, and `GooglePayService`.

## Minimal implementation scope

1. Add application-layer payment models:
   - `checkout_session.dart`
   - `payment_method.dart`
   - `payment_result.dart`
2. Add `google_pay_service.dart` with:
   - abstract `GooglePayService`
   - `GooglePayServiceStub`
3. Extend `mock_product_checkout.dart` with `buildMockCheckoutSession(...)`.
4. Add focused unit tests for:
   - mock checkout session structure
   - Google Pay stub availability/result semantics
5. Do **not** integrate real payment SDKs or backend calls.

## TDD path

### Step 1 — RED
- Add a test file for the new abstraction layer.
- Cover:
  - mock checkout session includes `googlePay` in supported payment methods
  - Google Pay stub reports unavailable by default
  - Google Pay stub returns a non-success placeholder result with no payment/order IDs

### Step 2 — GREEN
- Add the new model and service files.
- Update `mock_product_checkout.dart` with the smallest implementation needed to satisfy tests.

### Step 3 — REFACTOR
- Keep the API names aligned with the Google Pay planning doc.
- Avoid wiring the checkout page yet unless a tiny adapter becomes necessary.

## Files to change

- `lib/features/report/application/mock_product_checkout.dart`
- `lib/features/report/application/checkout_session.dart` (new)
- `lib/features/report/application/payment_method.dart` (new)
- `lib/features/report/application/payment_result.dart` (new)
- `lib/features/report/application/google_pay_service.dart` (new)
- `test/features/report/application/google_pay_service_test.dart` (new)

## Verification

- `flutter test test/features/report/application/google_pay_service_test.dart`
- `flutter analyze` on changed files
- `lsp_diagnostics` on changed Dart files
- Oracle read-only review after local verification

## Task-Level QA

### Task 1 — RED: abstraction expectations fail first
- Tool: `flutter test test/features/report/application/google_pay_service_test.dart`
- Steps:
  1. Add tests that import the planned abstraction files.
  2. Run the focused test file before production code exists.
- Expected result:
  - The test fails for the expected reason: missing abstraction/model implementation.

### Task 2 — GREEN: models and stub satisfy tests
- Tool: `flutter test test/features/report/application/google_pay_service_test.dart`
- Steps:
  1. Add the minimal model and stub implementation.
  2. Rerun the same focused test file.
- Expected result:
  - The focused test passes.
  - The stub still does not claim real payment success.

### Task 3 — REFACTOR: mock checkout builder aligns with abstraction
- Tool: `flutter test test/features/report/application/google_pay_service_test.dart`
- Steps:
  1. Extend `mock_product_checkout.dart` with the minimal mock session builder.
  2. Rerun the same focused tests.
- Expected result:
  - Mock checkout session data matches the abstraction shape.
  - Supported payment methods include `googlePay` without regressing existing preview logic.

### Task 4 — Changed-scope code health
- Tool: `lsp_diagnostics` and `flutter analyze`
- Steps:
  1. Run diagnostics on all changed Dart files.
  2. Run `flutter analyze` on the changed application/test files.
- Expected result:
  - No new diagnostics.
  - Analyze succeeds cleanly.

### Task 5 — Final review
- Tool: Oracle read-only review
- Steps:
  1. After tests and analyze pass, request an Oracle review of the changed abstraction files.
- Expected result:
  - Oracle confirms the implementation stays in the no-backend abstraction stage and does not overclaim real payment support.
