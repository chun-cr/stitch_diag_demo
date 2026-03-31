# Flutter Internationalization Plan

## Goal

Implement sustainable project-wide internationalization for this Flutter app using official `gen-l10n`, with minimal rework and without coupling business logic to localized display strings.

## Repository Facts

- Current app entry is `lib/main.dart` with `MaterialApp.router`.
- `pubspec.yaml` does not yet include `flutter_localizations`, `intl`, or `flutter.generate`.
- User-facing Chinese strings are hardcoded across multiple feature pages and widgets.
- Some business/sample data currently stores Chinese display values directly, especially constitution labels and risk labels.

## Non-Goals For First Pass

- Do not redesign app architecture beyond what is required for i18n.
- Do not fully remodel remote/domain data unless display-string coupling blocks localization.
- Do not attempt every low-value cosmetic string before the infrastructure and high-impact pages are stable.

## Phase 1 — Foundation

### Files
- `pubspec.yaml`
- `l10n.yaml`
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_en.arb`
- `lib/core/l10n/l10n.dart` or equivalent helper file

### Actions
1. Add `flutter_localizations` and `intl` dependencies.
2. Enable `flutter.generate: true`.
3. Add `l10n.yaml` pointing to `lib/l10n`.
4. Create initial ARB files with first-wave shared keys.
5. Add a small `BuildContext` extension or helper for `AppLocalizations` access.

### Verification
- Command: `flutter gen-l10n`
  - Expected: ARB files parse successfully and generated localization artifacts are created without errors.
- Command: `flutter analyze lib/main.dart`
  - Expected: generated localization imports resolve and no new localization setup errors appear.

## Phase 2 — App Entry Integration

### Files
- `lib/main.dart`

### Actions
1. Configure `MaterialApp.router` with:
   - `localizationsDelegates`
   - `supportedLocales`
   - localized app title path
2. Default behavior follows system locale.
3. Keep wiring compatible with future user-selected override.

### Verification
- Command: `flutter analyze lib/main.dart`
  - Expected: `MaterialApp.router` accepts localization delegates/locales with zero new errors.
- Manual/runtime check: launch app in default locale.
  - Expected: app boots normally, router still works, no missing delegate or null localization crash.

## Phase 3 — Locale State Source

### Files
- New locale provider/state file under existing Riverpod structure
- Possibly shared preferences integration point

### Actions
1. Add lightweight locale state using existing Riverpod.
2. Persist optional user language choice via `SharedPreferences`.
3. If no explicit choice exists, follow system locale.
4. Expose a clean `Locale?` source for `MaterialApp.router`.

### Verification
- Command: `flutter analyze lib/main.dart lib/**/locale*.dart`
  - Expected: locale state/provider compiles cleanly.
- Test: add/update a focused provider/helper test if helper logic is extracted.
  - Expected: unset preference returns follow-system behavior; explicit preference returns expected locale.

## Phase 4 — Shared/Common String Migration

### Priority Targets
- App title
- Bottom navigation labels
- Common buttons/actions
- Shared snackbars/toasts/messages
- Common scan widgets and hint widgets
- Reusable section titles/tags when user-facing

### Actions
1. Replace hardcoded strings in common/shared UI first.
2. Use placeholders for variable content instead of string concatenation.
3. Avoid introducing new hardcoded strings during migration.

### Verification
- Command: `flutter analyze lib/main.dart lib/core/router/app_router.dart lib/features/home/presentation/pages/home_page.dart lib/features/scan/presentation/widgets/*.dart`
  - Expected: migrated shared/common surfaces compile without hardcoded-access regressions.
- Test/manual check: boot app under Chinese and English locales.
  - Expected: bottom navigation, app title, common actions, and scan shared widgets show translated text and remain visually usable.

## Phase 5 — Business Display Value Decoupling (must precede affected page migration)

### Scope
Decouple only where localized display values are currently acting as identifiers.

### Files to start with
- `lib/features/history/presentation/pages/history_page.dart`

### Actions
1. Introduce stable codes/keys for display-sensitive business concepts where needed:
   - constitution types
   - risk labels
   - scan item labels where used as keys
2. Add mapping from stable keys to localized strings.
3. Preserve existing sample/demo behavior without large domain rewrites.

### Verification
- Command: `flutter analyze lib/features/history/presentation/pages/history_page.dart`
  - Expected: history page compiles with stable internal keys and localized labels.
- Test: add/update focused tests for code-to-label mapping or fallback helpers if logic is extracted.
  - Expected: unknown keys fall back predictably; chart/legend matching no longer depends on raw Chinese keys.

## Phase 6 — High-Impact Page Migration

### Priority Files
- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/history/presentation/pages/history_page.dart`
- `lib/features/report/presentation/pages/report_page.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/auth/presentation/pages/register_page.dart`
- `lib/features/scan/presentation/pages/*.dart`
- `lib/features/scan/presentation/widgets/*.dart`

### Actions
1. Migrate titles, subtitles, CTA text, dialog text, validation text, and chart/legend labels.
2. Replace direct Chinese literals with localized lookups.
3. Keep diffs scoped to localization, not visual redesign.

### Verification
- Command: `flutter analyze lib/features/home/presentation/pages/home_page.dart lib/features/history/presentation/pages/history_page.dart lib/features/report/presentation/pages/report_page.dart lib/features/profile/presentation/pages/profile_page.dart lib/features/auth/presentation/pages/login_page.dart lib/features/auth/presentation/pages/register_page.dart lib/features/scan/presentation/pages/*.dart lib/features/scan/presentation/widgets/*.dart`
  - Expected: migrated files have no new diagnostics from localization changes.
- Manual/runtime check: run app in Chinese and English across home/auth/scan/report/history/profile flows.
  - Expected: no missing translations in migrated scope, no obvious overflow/crash in key screens.

## Phase 7 — Localized Formatting

### Actions
1. Replace handwritten date formatting with localized formatting helpers.
2. Use placeholders/localized formatters for score, percent, days-ago strings, and similar dynamic content.
3. Keep formatting rules centralized where practical.

### Verification
- Command: `flutter analyze lib/features/home/presentation/pages/home_page.dart lib/features/history/presentation/pages/history_page.dart lib/features/report/presentation/pages/report_page.dart`
  - Expected: migrated formatting helpers compile cleanly.
- Manual/runtime check: inspect date, score, percent, days-ago strings under Chinese and English locales.
  - Expected: strings follow locale-aware wording/order and no handwritten concatenation remains in migrated hotspots.

## Phase 8 — QA and Regression Pass

### Actions
1. Run `flutter analyze`.
2. Fix any generated-import and context/localization errors.
3. Review layout regressions caused by longer English text.
4. Check major user flows under Chinese and English.

### Verification
- Command: `flutter analyze`
  - Expected: either fully clean or only pre-existing unrelated warnings are reported and documented.
- Command: `flutter test`
  - Expected: existing tests plus any added locale/helper tests pass.
- Manual/runtime check: verify major routes, dialogs/snackbars, chart labels, bottom navigation, and auth flow under Chinese and English.
  - Expected: core user flows remain usable and no business logic depends on translated strings.

## Execution Notes

- Prefer phased commits conceptually, even if actual git commit is deferred until user requests.
- Keep first pass pragmatic: infrastructure + high-impact migration + necessary decoupling.
- Avoid full domain refactors unless a Chinese display string is being used as an application key.

## Atomic Commit Strategy

1. `chore`: add l10n infrastructure and app wiring
2. `feat`: add locale state/persistence
3. `refactor`: migrate shared/common strings
4. `refactor`: decouple business display keys where required for i18n
5. `refactor`: migrate feature pages by slice
6. `chore`: formatting cleanup and verification fixes

## TDD-Oriented Checks

- For helper/provider logic, add or update focused tests if test structure already exists nearby.
- Add focused tests for locale state/fallback helpers and any extracted code-to-label mapping helpers.
- For UI-heavy migration with little existing widget coverage, prefer executable verification via analyze and focused manual runtime-safe checks.
- Do not invent broad test infrastructure solely for i18n if the repo does not already support it in that area.
