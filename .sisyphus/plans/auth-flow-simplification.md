# Auth Flow Simplification

## Goal

Simplify the Flutter auth experience so login/register align with a phone-first product direction while preserving the current polished UI style and existing password strength flow.

## Approved Scope

1. Login page removes email-login mode and becomes phone-only
2. Login page keeps WeChat login and Apple login
3. Register page changes name to nickname
4. Register page changes phone/email field to phone-only and validates phone format
5. Register page gender becomes required
6. Register page removes unnecessary breathing/pulse animation
7. Password validation remains intact

## Non-Goals

1. No backend or API changes
2. No register-page country-code popover unless current implementation forces it
3. No redesign of the full auth visual system
4. No new dependencies

## Current Findings

### Login page
- `login_page.dart` still uses `_isPhoneLogin` to switch between email and phone mode
- default state is email mode
- phone mode already has country-code prefix selection
- current validator only checks emptiness, not phone format

### Register page
- step 1 still uses:
  - `authNameLabel`
  - `authEmailOrPhoneLabel`
  - `registerGenderOptional`
- gender selection state currently lives inside `_GenderSelector`, so parent step validation cannot require it
- `_pulseController` drives the visible breathing/pulse effect in register visuals

## Planned Changes

### 1. Login page → phone-only
- remove the email/phone toggle UI and email-only branch logic
- keep the country-code selector and phone input
- use phone-specific label/hint/validation copy only
- keep WeChat and Apple login row as-is

### 2. Register page → nickname + phone + required gender
- rename top name field to nickname via i18n
- convert the phone/email field into phone-only
- use phone keyboard and phone-format validator
- change gender label from optional wording to required wording
- lift selected gender state into the parent page so `_nextStep()` can enforce it before moving to step 2

### 3. Remove breathing/pulse animation on register page
- remove `_pulseController` and pulse-based size/alpha changes that create breathing motion
- keep static visuals and any non-obtrusive decoration still needed for page polish

### 4. Validation behavior
- login phone field: required + phone format validation
- register phone field: required + phone format validation
- register gender: required before next step
- password rules stay unchanged:
  - min length
  - strength indicator
  - confirm password mismatch validation

### 4.1 Phone validation rule
- Use one shared acceptance rule across login and register UI behavior:
  - input is the local phone number part only
  - digits only
  - length 6-15
- Accepted examples:
  - `13800138000`
  - `912345678`
  - `0712345678`
- Rejected examples:
  - `12345` (too short)
  - `1234567890123456` (too long)
  - `abc123456`
  - `138-0013-8000`
  - `+8613800138000`
- Login page keeps the selected country code separately in the prefix selector; validation only applies to the typed local-number segment.
- Register page follows the same local-number rule even though it does not add a country selector in this pass.

## I18n Plan

Update all four locale files:
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_ko.arb`

Likely keys to reuse:
- `authPhoneLabel`
- `authPhoneHint`

Likely keys to add or update:
- nickname label / hint
- required gender label or equivalent wording
- phone-format error message if no reusable key exists

## TDD Plan

Write failing tests first for:

1. Login page no longer exposes email-mode UI/copy
2. Login page phone-only field validates format
3. Register page shows nickname label
4. Register page requires gender before continuing to step 2
5. Register page phone field validates format
6. Register page no longer uses breathing/pulse visual seam

## Verification

### 1. Login page phone-only regression
- Tool: `flutter test`
- Scope: focused login auth tests
- Steps:
  1. render login page
  2. verify email-mode toggle/copy is gone
  3. verify phone label/hint is shown
  4. enter invalid phone and trigger submit
- Expected:
  - no email-login toggle remains
  - phone-only copy renders
  - invalid phone is rejected

### 2. Register step-1 semantics
- Tool: `flutter test`
- Scope: focused register auth tests
- Steps:
  1. render register page step 1
  2. verify nickname label/hint
  3. verify phone-only label/hint
  4. verify gender label is not optional
  5. attempt next step with missing gender or invalid phone
- Expected:
  - nickname/phone labels render correctly
  - gender is required
  - step 1 does not advance when phone or gender is invalid

### 3. Password validation continuity
- Tool: `flutter test`
- Scope: focused register auth tests
- Steps:
  1. advance to step 2 with valid step-1 data
  2. enter short password and mismatched confirmation
- Expected:
  - existing password min-length validation still fires
  - confirmation mismatch validation still fires

### 4. Register pulse removal
- Tool: `flutter test`
- Scope: focused register auth tests
- Steps:
  1. render register page
  2. inspect a keyed visual seam that previously pulsed
  3. pump time forward
- Expected:
  - no pulse-driven size or alpha change remains on the keyed seam

### 5. Localization/codegen
- Tool: `flutter gen-l10n`
- Expected:
  - new/updated auth keys generate successfully across zh/en/ja/ko

### 6. Static analysis
- Tool: `flutter analyze`
- Scope: changed auth files and focused tests
- Expected:
  - no new diagnostics

### 7. Runtime smoke test
- Tool: `flutter run -d windows`
- Steps:
  1. launch app
  2. open login page
  3. open register page
- Expected:
  - both pages launch without runtime errors
  - login shows phone-first flow
  - register page remains navigable through both steps

## Risks

1. If phone validation is too narrow, it may conflict with the login page’s country-code selector semantics
2. Lifting gender state incorrectly could break the selector UI or step progression
3. Removing pulse animation must not leave dead controllers or stale animated builders behind
