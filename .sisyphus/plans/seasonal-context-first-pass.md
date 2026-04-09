# Seasonal Context First Pass

## Goal

Introduce a shared, dependency-free seasonal/solar-term capability for the Flutter app and reuse it in the approved first-pass surfaces.

## Approved Scope

1. Login page seasonal tag
2. Home page today-care seasonal tag
3. Report page seasonal-care current recommendation/title area

## Non-Goals

1. Do not redesign the report seasonal-care four-season knowledge cards
2. Do not change unrelated wellness copy across the app in this pass
3. Do not add third-party calendar or solar-term packages

## Plan

### 1. Shared seasonal context
- Add a core utility that resolves from `DateTime`:
  - current season
  - current solar term
  - associated five-element label
- Keep logic centralized so pages consume a value object instead of calculating locally.

### 2. Localization
- Reuse existing season/five-element keys where possible.
- Add missing solar-term display keys in all ARB files.
- Add minimal generic localized labels/placeholders needed for the report current recommendation/title area.

### 3. UI wiring
- Login page: replace fixed `authSeasonalTag` with shared current seasonal tag.
- Home page: replace fixed `homeTodayCareSeasonTag` with shared current seasonal tag.
- Report page: keep four static season cards, but add a current-season/current-solar-term recommendation header/title driven by shared context.

### 4. Tests
- Add focused unit tests for the resolver around representative term boundaries.
- Add at least one widget/smoke test proving a consumer page/module can initialize and render with the new shared context.

### 5. Verification

#### 5.1 Localization generation
- Command: `flutter gen-l10n`
- Expected: new solar-term keys generate successfully with no ARB errors.

#### 5.2 Resolver unit tests
- Command: `flutter test test/core/l10n/seasonal_context_test.dart`
- Scenarios:
  - a date just before a configured solar-term boundary resolves to the previous term
  - the boundary date resolves to the next solar term
  - representative dates in spring/summer/autumn/winter resolve to the correct season and five-element label
- Expected: all assertions pass and no fallback/hardcoded display values are required in page code.

#### 5.3 Consumer rendering test
- Command: `flutter test test/features/auth/presentation/pages/login_seasonal_tag_test.dart`
- Scenarios:
  - render at least one consuming page with the shared seasonal context enabled
  - verify the login page seasonal tag matches the shared seasonal/solar-term label without hardcoded fallback copy
- Expected: consuming page initializes and renders current seasonal content successfully.

#### 5.4 Static analysis
- Command: `flutter analyze lib/core/l10n/seasonal_context.dart lib/features/auth/presentation/pages/login_page.dart lib/features/home/presentation/pages/home_page.dart lib/features/report/presentation/pages/report_page.dart test/core/l10n/seasonal_context_test.dart test/features/auth/presentation/pages/login_seasonal_tag_test.dart`
- Expected: no new diagnostics in changed production files and focused tests.

#### 5.5 Locale UI spot-check
- Tool/flow: run the app and switch locale where applicable, or use focused widget assertions.
- Pages:
  - login page seasonal tag
  - home page today-care seasonal tag
  - report seasonal-care current recommendation/title area
- Locales: `zh`, `en`, `ja`, `ko`
- Expected: seasonal labels render in all active locales with no obvious overflow/truncation regressions in the touched UI.

## Risks to Watch

1. Hardcoding user-visible text in Dart instead of ARB
2. Date-boundary mistakes around solar-term transitions
3. Expanding report seasonal-care scope beyond the approved first pass
