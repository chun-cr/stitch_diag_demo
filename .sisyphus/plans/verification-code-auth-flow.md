# Verification Code Auth Flow

## Goal

Integrate the mobile verification-code auth contract into the Flutter auth funnel while preserving the existing visual language and the newly split account-creation → complete-profile flow.

## Scope

1. Login page: use challenge → send → authenticate for verification-code login
2. Login page: keep password login as a secondary/manual switch path
3. Register page: change account creation from phone+password to phone+verification-code
4. Register page / login page: track challenge state, resend timing, and reset rules correctly
5. Keep complete-profile page and post-auth routing intact

## Non-Goals

1. Do not integrate captcha SDK provider in this pass unless already available
2. Do not redesign CompleteProfilePage again
3. Do not change backend contracts
4. Do not remove password login from login page in this pass

## Contract Summary

### Shared verification-code flow
1. `POST /api/v1/saas/mobile/auth/verification-code/challenge`
2. Optional `POST /api/v1/saas/mobile/auth/verification-code/captcha/verify`
3. `POST /api/v1/saas/mobile/auth/verification-code/send`
4. `POST /api/v1/saas/mobile/auth/verification-code/authenticate`

### Scene values
- login page → `LOGIN`
- register page → `REGISTER`

### Important client rules
- save and reuse `challengeId`
- resend uses the same `challengeId`
- countdown should use `resendAt`, not a hardcoded 60s default
- `11119` / `11121` invalidate the current challenge and must restart from challenge
- `11120` should keep current challenge and continue countdown based on `resendAt`

## Current Repo State

### Already present
- phone-first login UI with password/code switch
- register page account-creation UI is already phone + verification code + terms
- `AuthSessionEntity`, session store, interceptor, startup restore, logout clear
- split register flow: register page → complete profile page
- real password login and password register endpoints already wired

### Missing for verification-code auth
- challenge/send/authenticate request/response models
- verification-code remote methods and repository methods
- challenge state storage in page state
- resendAt/expireAt-aware countdown
- REGISTER scene account creation using verification code instead of password register
- handling for `captchaRequired`

## Planned Implementation

### 1. Data / domain layer
- Add models for:
  - challenge response
  - captcha verify response
  - send response
  - authenticate response (reuse existing auth session parsing)
- Extend repository with:
  - `challengeCodeAuth(...)`
  - `verifyCodeCaptcha(...)`
  - `sendCodeChallenge(...)`
  - `authenticateCode(...)`

### 2. Login page behavior
- Default mode remains verification code
- `_onSendCode()` becomes:
  1. validate phone
  2. challenge with `scene=LOGIN`
  3. if `captchaRequired=true`, stop and surface a temporary "当前环境未接入人机验证" error path
  4. otherwise send by `challengeId`
  5. set countdown using `resendAt`
- Login submit in code mode uses `authenticateCode(challengeId, verificationCode)`
- Password mode remains intact and uses current password-login API

### 3. Register page behavior
- Register page already is phone + verification code + terms only
- Remove password / confirm password from account-creation page
- Send code uses `scene=REGISTER`
- Submit uses `authenticateCode(challengeId, verificationCode)`
- Success stores session and routes to complete profile page

### 4. Error handling
- `11119` / `11121` → reset current challenge state and tell user to retry from the start
- `11120` → keep current challenge and use backend `resendAt`
- `11122` / `11123` → surface a clear temporary unsupported-captcha message in this pass
- `11118` → keep on current page, show invalid-code error

## TDD Plan

Write failing tests first for:
1. login challenge/send success enters countdown using backend state
2. login invalid/expired challenge resets state correctly
3. register challenge/send success enters countdown using backend state
4. successful register verification routes to complete profile page
5. password login path still works as a secondary mode

## Verification

1. `flutter gen-l10n`
2. focused auth widget tests
3. focused `flutter analyze`
4. `flutter run -d windows`
5. `flutter build web`

## Risks

1. Captcha provider integration is not specified, so captcha-required flows can only be handled gracefully, not completed, in this pass
2. Replacing register password flow with verification code will require test updates across auth pages
3. Countdown based on `resendAt` must account for local clock drift conservatively
