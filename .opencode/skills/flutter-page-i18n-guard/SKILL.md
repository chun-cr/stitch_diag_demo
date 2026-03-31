---
name: flutter-page-i18n-guard
description: Use when adding or modifying any Flutter page, widget, menu, card, form, dialog, report, scan guide, or locale-related behavior in this project, especially when user-visible text may be introduced, changed, or expanded to new languages. Apply it before finishing UI work so new copy, multilingual layout safety, locale onboarding, and verification are all handled through the existing gen-l10n workflow instead of hardcoded text or ad hoc fixes.
---

# Flutter Page I18n Guard

## Overview

This is the project-wide Flutter internationalization delivery skill.

It is not only for “extract strings”. It is the full workflow for:

1. page-level internationalization
2. multilingual UI safety
3. adding a new locale
4. verification and minimum regression protection

If a Flutter page changes and users can see text, this skill applies.

This repository already uses:

- `flutter gen-l10n`
- ARB files in `lib/l10n/`
- `context.l10n`
- locale switching in `Profile`
- locale persistence via `locale_controller`
- active locales:
  - `zh`
  - `en`
  - `ja`
  - `ko`

Use the existing system. Do not invent a second one.

---

## When to Use

Use this skill whenever you:

- add a new Flutter page
- modify an existing page
- change any user-facing text
- add a new button, card, menu item, tab, status line, tooltip, banner, dialog, snackbar, form field, or report section
- add a new locale
- change any text that may affect layout length
- update scan / report / profile / home copy
- restore or update tests after localization work

Apply this skill even if:

- the change is “small”
- the page is “temporary”
- the text is “just for now”
- only one locale is being discussed

If the user can see the text, this skill must run.

---

## Four Modes

This skill contains four required modes. Use the relevant ones based on the task, but keep them in one continuous workflow.

### Mode A — Page Development Internationalization

Use when adding or changing user-visible text in Flutter UI.

### Mode B — Multilingual UI Inspection

Use when localized text may affect layout, spacing, truncation, tabs, chips, cards, menu rows, buttons, or hero sections.

### Mode C — New Locale Bootstrapping

Use when introducing a new language file such as `app_ja.arb` or `app_ko.arb`, or extending the locale switcher.

### Mode D — Verification and Regression Guardrails

Use before claiming the work is done.

---

## Mode A — Page Development Internationalization

### Step A1 — Detect user-visible text

Before finishing any Flutter UI change, check whether you introduced or modified:

- `Text(...)`
- `RichText(...)`
- `TextSpan(...)`
- labels in arrays/maps used by widgets
- tab names
- menu titles/subtitles
- button labels
- status messages
- helper descriptions
- placeholders
- tooltip text
- snackbar/dialog text
- report/scan descriptions
- chart legends and tags

If users can see it, it must be localized.

### Step A2 — Reuse before creating keys

Before creating a new key:

1. search existing ARB keys
2. reuse existing wording if the meaning is the same
3. only create a new key when the copy is genuinely new

Examples:

- reuse `common*` labels like save/cancel/view details
- reuse diagnosis names like face/tongue/palm
- reuse report terminology when concept matches

Do not create duplicate keys with slightly different names for the same meaning.

### Step A3 — Add keys in all locales

If a new key is needed, add it to:

- `lib/l10n/app_zh.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_ko.arb`

Never update only one language file.

Even if copy is not fully polished in `en/ja/ko`, still add all keys with the best available draft.

### Step A4 — Use semantic naming

Prefer intent-based key names.

Good:

- `homeQuickScanTitle`
- `profileMenuLanguage`
- `reportOverviewDiagnosisSummaryTitle`
- `scanGuideWarmPromptTitle`

Bad:

- `text1`
- `titleNew`
- `labelA`
- `greenCardTitle`

Use `common*` for shared concepts.

### Step A5 — Use placeholders correctly

Never build user-facing dynamic text with manual concatenation.

Bad:

```dart
'上次检测 ${days}天前'
```

Good:

- ARB placeholder
- generated localization method

Typical placeholder cases:

- time ago
- score with unit
- percentage
- title with username

Always add placeholder metadata in ARB.

### Step A6 — Replace literals in Dart

After keys exist, use `context.l10n`.

Bad:

```dart
Text('体质分析')
```

Good:

```dart
Text(context.l10n.homeFunctionConstitution)
```

Do not keep fallback literals in page code.

### Step A7 — Preserve business/display separation

Do not use localized strings as business keys.

Never:

- compare logic against translated labels
- use localized display text as map keys
- branch routing or behavior using translated text

Use stable enums or codes, then map them to localized labels.

This is especially required for:

- constitution type
- risk category
- scan labels
- report category labels

---

## Mode B — Multilingual UI Inspection

### Step B1 — Identify high-risk layouts

Review localized text in tight containers, especially:

- `Row`
- `TabBar`
- chips / pills / tags
- CTA buttons
- menu rows
- hero headers / meta rows
- card titles/subtitles
- bottom navigation
- status lines
- scan guide step rows
- report module cards

### Step B2 — Apply minimal layout safety

Use the smallest safe fix:

- `maxLines`
- `overflow: TextOverflow.ellipsis`
- `Flexible`
- `Expanded`
- scrollable tabs where needed
- mild layout rebalance only if absolutely necessary

Do not redesign UI unless the user asked for redesign.

### Step B3 — Check all active locales

At minimum, consider behavior under:

- `zh`
- `en`
- `ja`
- `ko`

Do not optimize only for Chinese or only for English.

### Step B4 — Prefer readability over literal full display in tight UI

For tight rows/cards/buttons:

- keep the most important information visible
- truncate secondary text where appropriate
- allow multi-line only when visually safe

Do not force long localized strings into rigid single-line UI without protection.

---

## Mode C — New Locale Bootstrapping

Use this mode when adding a new language.

### Step C1 — Add ARB file

Create:

- `lib/l10n/app_xx.arb`

Start with:

- app shell
- navigation
- common actions
- auth
- home
- history
- profile
- report
- scan

### Step C2 — Register locale

Update:

- `supportedAppLocales`
- any locale picker display labels
- locale label mapping logic in UI

### Step C3 — Get to “runnable first”

Do not aim for perfect translation first.

The order is:

1. locale wired in
2. app runs
3. high-frequency pages covered
4. missing keys driven toward zero
5. language quality polish afterward

### Step C4 — Reuse previous locale as template

When adding a new locale:

- use `app_en.arb` as structural baseline
- use `app_ja.arb` / `app_ko.arb` as process templates once they exist

Do not manually invent a different structure for one locale.

---

## Mode D — Verification and Regression Guardrails

### Step D1 — Always regenerate

After ARB changes:

- run `flutter gen-l10n`

### Step D2 — Always analyze

Run `flutter analyze` on changed scope.

Minimum:

- changed page files
- `lib/main.dart`
- `lib/core/l10n/*` when locale wiring changed

### Step D3 — Run app when UI or locale behavior changed

If any of these changed, run the app:

- language switcher
- supported locales
- page UI under localization
- scan/report/home/profile layout behavior

### Step D4 — Update tests when relevant

If localization helpers, enum-label mapping, navigation, or locale switching changed, update or add tests.

This repository now has a minimum baseline around:

- locale helpers
- history enum-label mapping
- language switch smoke test

Do not break these silently.

---

## Mandatory Checks

Before claiming completion, verify all of these:

- [ ] No new hardcoded user-visible strings remain in changed Flutter UI
- [ ] New keys were added to all locale ARB files
- [ ] Placeholder metadata exists where needed
- [ ] Existing keys were reused where possible
- [ ] No business logic depends on translated strings
- [ ] Tight layouts got overflow protection if needed
- [ ] `flutter gen-l10n` passes
- [ ] `flutter analyze` passes for changed scope
- [ ] If app behavior changed, runtime launch was checked
- [ ] Relevant tests were updated or at least reviewed

---

## Red Flags — Stop and Fix

If any of these are true, the work is not done:

- you added a `Text('...')` literal for user-facing content
- only one locale ARB was updated
- `ja/ko` keys were skipped “for later”
- dynamic text was built by string concatenation in Dart UI
- translated text is used for matching logic
- layout got longer but no overflow review happened
- you changed ARB files without running `flutter gen-l10n`
- you changed locale flow without running app
- you changed i18n logic without checking tests

All of these mean:
**stop and finish the i18n workflow properly.**

---

## Must Not Do

- Do not hardcode Chinese in page code
- Do not hardcode English in page code
- Do not hardcode Japanese in page code
- Do not hardcode Korean in page code
- Do not leave missing locale keys behind
- Do not compare business logic against localized display text
- Do not create duplicate ARB keys without checking existing usage
- Do not add a second localization system
- Do not defer i18n to a later cleanup pass
- Do not add a new locale without wiring it into picker/support/locales consistently

---

## Output Format for Future Models

When this skill is applied, final reporting should include:

1. what text or locale behavior changed
2. which ARB keys were added, reused, or updated
3. which files were updated
4. whether UI overflow protection was added
5. whether a new locale was introduced or expanded
6. verification run:
   - `flutter gen-l10n`
   - `flutter analyze`
   - `flutter test` if relevant
   - app run if relevant

Example:

- Added localized keys for new scan status and reused common action labels
- Updated:
  - `lib/features/scan/...`
  - `lib/l10n/app_zh.arb`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_ja.arb`
  - `lib/l10n/app_ko.arb`
- Added `maxLines + ellipsis` for the guide CTA and step title row
- Verified with `flutter gen-l10n`, `flutter analyze`, and app launch

---

## Project-Specific Notes

For this repository, always pay extra attention to:

- `home_page.dart`
- `report_page.dart`
- `scan_*`
- `profile_page.dart`
- chart labels / legend text
- menu subtitles
- report long-form copy
- locale picker behavior

These are the highest-risk i18n areas in this codebase.

---

## One-Line Rule

**If the user can see the text, it belongs in ARB before the task is considered done — and if the layout can break in another locale, that must be checked before completion.**
