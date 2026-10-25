# Action Label and Symbol Options

- Date: 2026-10-25
- Status: Accepted native-only object/action refinements and concise wording;
  earlier choices retained as history
- Tracking: [#163](https://github.com/muhiro12/Cookle/issues/163)
- Decision: [ADR 0013][decision]

## Accepted Baseline

Recipe creation uses `book.pages`. Diary addition uses `book.badge.plus` on
iOS 26 or later and `book` on iOS 18. `DiaryAdditionLabel` shares that symbol
availability policy between new-Diary creation and adding an existing recipe to
today's Diary. Their localized titles and action callbacks remain distinct.

The native-only choice supersedes creation pair C's Diary compose symbol.
Recipe and Diary creation remain visually distinct when placed together.

The shared-control audit covered 23 button types. Reusable cancellation appears
in nine placements, completion in four, and import confirmation in two. Existing
edit/delete/duplicate behavior and destructive confirmations remain intact.

## Native-Only Object and Action Refinement

Use existing SF Symbols only. Do not overlay symbols, draw badges, or create
composite object/action images. Prefer a recognizable object plus an operation
where a suitable native symbol exists; do not reinterpret a slash as deletion.

The selected follow-up changes are:

- Diary creation: `square.and.pencil` becomes `book.badge.plus` on iOS 26 or
  later, with `book` on iOS 18. The existing-recipe-to-Diary action shares the
  same label component's availability handling.
- Adding one generation preference: `plus` becomes `text.badge.plus`.
- Editing the generation preference list: `pencil.line` becomes
  `pencil.and.list.clipboard`.
- Data export: `square.and.arrow.up` becomes `tray.and.arrow.up` in Settings
  and the export-before-import action, pairing with import's tray/down arrow.

These changes preserve wording, input and generation behavior, import/export
callbacks, cancellation, and the recipe/Diary save contracts. Native object
variants do not cover editing or deleting the existing book, photo, and Tag
bases, so those actions retain their current symbols. Bulk step input keeps its
numbered-list identity rather than adopting an unnumbered clipboard.

### Why Diary Addition Needs an Availability Check

Cookle first used `book.badge.plus` in `0d900322` on 2026-04-10 for the
recipe-detail shortcut to today's Diary. Both Apple's SF Symbols app metadata
and the system symbol catalog record its introduction as 2025 / iOS 26. The
base `book` predates this decorated variant.

An existing source reference is not evidence of older-OS availability:
`Image(systemName:)` accepts a string, so compilation against an iOS 18
deployment target does not validate the symbol's presence there. The shared
label now selects the older native `book` before iOS 26, avoiding the previous
unguarded reference. This is a symbol fallback, not a manual text/icon style
override or a change to the app's deployment target.

### Native-Only Follow-Up Verification

- The current Cookle build succeeded with zero raw warnings or errors.
  Formatting and retained repository checks, including 28 script checks, passed.
- Live iPhone 18 Pro / iOS 27.2 checks used isolated in-memory sample data.
  Recipe/Diary creation remained distinguishable in the toolbar, both Diary-add
  labels used book-plus, and new-Diary entry/Cancel navigation succeeded.
- Generation preference addition and list editing displayed the selected
  native symbols. A sample preference was added, its editor opened, and Done
  returned without changing its text. No model request was made.
- Settings export and the export-before-import action both displayed tray/up.
  Neither export nor import was executed. The existing developer run and Xcode
  selection were preserved; only the isolated verification runs were stopped.
- No iOS 18 runtime was installed. The fallback is verified by source and the
  iOS 18 deployment-target build, not by an older-OS live run. This follow-up
  makes no new iPad or spoken VoiceOver qualification claim.

## Selected Refinements

The owner selected the alternative **icons only** for B1, B3, B7, F3, F6, N1,
N2, N3, and N4. The implementation uses:

- B1: `pencil.line` for Recipe, Diary, and Tag editing. Edit Request later
  adopts the native clipboard/pencil above. Manual entry retains `pencil`.
- B3: `plus.square.on.square` for recipe duplication.
- B7: `tray.and.arrow.down` for import confirmation and the Settings import
  entry. The review stage and actual import remain separate actions.
- F3: `list.bullet.rectangle` for bulk ingredient input. Bulk steps retain
  the ordered-list symbol `list.number`.
- F6: `checkmark` for new and existing form confirmation, including recipe
  registration from a Diary. Creation entry points retain their own symbols.
- N1: `play` for resuming cooking.
- N2: `clock.arrow.circlepath` for the last-opened recipe.
- N3: `lightbulb` in the existing Preview-only Diary suggestion component.
  No live entry point is added.
- N4: `tag` for Browse Tags; Sort retains `arrow.up.arrow.down`.

Other icons retain their baseline. Selecting an icon does not select its wording
alternative or authorize changing unrelated uses of the same SF Symbol.

## Wording Decision

Prefer concise titles because available space varies by placement and language.
Change wording at comparable length when it clarifies meaning; use more words
only when needed to avoid a misleading interpretation. Preserve interpolated
object names where they identify the target. Do not abbreviate away meaning or
compensate for long copy with forced label styles.

Three titles change in all five supported languages:

<!-- markdownlint-disable MD013 -->

| ID | Previous English title | Selected English title | Japanese title |
| --- | --- | --- | --- |
| F3 | Add Multiple Ingredients at Once | Enter Ingredients Together | 材料をまとめて入力 |
| F4 | Add Multiple Steps at Once | Enter Steps Together | 手順をまとめて入力 |
| F5 | Privacy Options | Ad Privacy Options | 広告のプライバシー設定 |

<!-- markdownlint-enable MD013 -->

The bulk editors also edit existing input, so "Add" incorrectly narrows their
purpose. The new titles are shorter in every supported language. Advertising
privacy appears among general Settings actions; naming ads avoids implying
app-wide privacy controls. English, French, and Simplified Chinese add a short
qualifier; Japanese and Spanish stay the same length.

Keep Edit, Duplicate, Cancel, Done, and Import concise. "Edit Content" and
"Duplicate and Edit" add little in their object context; "Apply" does not fit
all Done placements, including leaving reorder mode. Keep Share Recipe Link
because "Save" could imply automatic saving instead of opening a share sheet.
Keep the existing Diary and merge terminology pending the broader vocabulary
work. Resume Cooking already describes the action. Back to Last Opened appears
beside the recipe name; "Previous Recipe" could imply list order instead of
history. Browse Tags already names its destinations without the longer
"Ingredients and Categories". Recipe Tools covers both input and generation.
The Preview-only suggestion retains its specific recipe/meal title.

## How to Review the Remaining Options

The tables preserve the original baseline and alternatives. The selected icon
IDs above and three wording decisions resolve the corresponding alternatives;
other alternatives remain unselected. Retaining a symbol is a valid outcome.
Review symbols and wording independently. Unselected wording
examples describe intent rather than final localized strings.

Compare both icon-only and title-plus-icon contexts, adjacent actions, toolbar
overflow, Dynamic Type, and navigation versus content actions. Check selected
symbols against the actual deployment target. A border built into a symbol can
duplicate the native toolbar container. Distinguish creating an object,
applying form input, adding a relationship, and saving persisted data.

<!-- markdownlint-disable MD013 -->

## Basic Actions

| ID | Family and baseline symbol | Candidate | Decision |
| --- | --- | --- | --- |
| B1 | Edit Recipe, Diary, and Tag: `pencil` | `pencil.line`; wording such as "Edit Content" where appropriate | Selected `pencil.line` for editing; retain concise Edit titles. Diary addition later adopts the native book-plus/fallback policy above. |
| B2 | Delete Recipe, Diary, Photo, Ingredient, and Category: `trash` | `trash.fill` | Retain `trash` for consistency. Fill is a weight/emphasis choice, not a different operation. Do not use an unlink or minus symbol for destructive deletion. |
| B3 | Duplicate Recipe: `document.on.document` | `plus.square.on.square`; "Duplicate and Edit" | Selected `plus.square.on.square`; retain Duplicate. The symbol emphasizes creating a copy; the editable draft and explicit Create confirmation remain. |
| B4 | Close: `xmark` | `xmark.circle` | Retain `xmark`. The circle can create a double border in native toolbars; it is not an improvement merely because the old implementation used a circled symbol. |
| B5 | Cancel: `xmark` and "Cancel" | Keep the symbol; a contextual title such as "Cancel Editing" | Retain the generic title for the shared control. A more specific title is a placement-level wording proposal, not a reason to replace cancellation callbacks or their confirmation policy. |
| B6 | Done: `checkmark` and "Done" | Keep the symbol; "Apply" in selection or bulk-input contexts | Retain the checkmark. "Apply" may clarify changes to the parent draft, but does not fit simply leaving reorder mode. Never imply that all Done actions persist a recipe or Diary. |
| B7 | Import confirmation: `square.and.arrow.down` | `tray.and.arrow.down`; "Import Data" | Selected `tray.and.arrow.down` for confirmation and Settings entry; retain concise Import wording. Preserve review/import stages and disabled/error states. |
| B8 | Recipe link sharing: `link` | `square.and.arrow.up`; "Save Recipe Link" | The share symbol matches the native sheet operation; `link` emphasizes the payload. The current footer explains that this is a reference for reopening Cookle, not sharing recipe contents, so keeping `link` is reasonable. A Save title must not imply an automatic save. |

## Content and Form Actions

| ID | Family and baseline symbol | Candidate | Decision |
| --- | --- | --- | --- |
| F1 | Add existing recipe to today's Diary, button and submenu: `book.badge.plus` | `calendar.badge.plus`; "Add to Today's Meal" | Retain `book.badge.plus`. A calendar emphasizes the date but may suggest scheduling rather than recording food. Keep this separate from creating a new Diary. |
| F2 | Merge duplicate Tags: `arrow.triangle.merge` | `arrow.merge`; "Review Duplicates" | These names render alike in the current comparison; this is primarily a wording option, not a reason for symbol-name churn. A review title must not imply automatic normalization or change which saved Tag is kept. |
| F3 | Bulk ingredients: `list.bullet` | `list.bullet.rectangle`; "Enter Ingredients Together" | Selected `list.bullet.rectangle` and Enter Ingredients Together. The rectangle identifies the list editor; wording includes editing existing input. |
| F4 | Bulk steps: `list.number` | `text.alignleft`; "Enter Steps Together" | Retain `list.number` for ordered steps. Select Enter Steps Together, independently of the unselected symbol alternative. |
| F5 | Advertising privacy options: `hand.raised` | `lock.shield`; "Ad Privacy Options" | Retain `hand.raised`; a shield can imply security. Select Ad Privacy Options to identify the SDK entry among general Settings actions. |
| F6 | Form confirmation: new `plus`, existing `checkmark` | `checkmark` for both; retain Create/Update titles | Selected `checkmark` for new and existing forms. Retain Create/Update/Add/Register titles, saving behavior, and role availability. |

## Contextual Navigation and Assistance

| ID | Family and baseline symbol | Candidate | Decision |
| --- | --- | --- | --- |
| N1 | Resume Cooking: `fork.knife.circle` | `play`; "Continue Cooking" | Selected `play`; retain Resume Cooking. The unbordered symbol communicates resuming an activity while the title and recipe name provide context. |
| N2 | Back to Last Opened: `arrow.uturn.backward.circle` | `clock.arrow.circlepath`; "Open Previous Recipe" | Selected `clock.arrow.circlepath`; retain Back to Last Opened alongside the recipe name. History distinguishes reopening a recipe from undo. |
| N3 | Diary top suggestion: `sparkles` | `lightbulb`; a title that explicitly opens a Diary draft | Selected `lightbulb`, identifying a suggestion without implying AI. Preserve the specific recipe/meal title and Preview-only placement. |
| N4 | Browse Tags menu: `line.3.horizontal.decrease` | `tag`; "Ingredients and Categories" | Selected `tag`; retain Browse Tags. The symbol identifies the destinations and remains distinct from Sort. |
| N5 | Recipe Tools menu: `wand.and.stars` | `doc.text`; "Recipe Input Tools" | The current symbol accommodates assisted editing. A document emphasizes text intake but underrepresents generation. Consider the whole menu's contents before choosing. |
| N6 | Sort: `arrow.up.arrow.down` | `arrow.up.arrow.down.circle` | Retain the unbordered arrows. The circled variant can duplicate the native container. Keep sorting distinct from tag browsing/filter-like actions. |

<!-- markdownlint-enable MD013 -->

## Boundaries

- Only the selected refinements and wording decisions above are approved for
  implementation; a remaining alternative is not approved by appearing here.
- Preserve native alert/confirmation labels and roles. Context-specific timer
  values and selection/content labels can carry independent information that
  must remain visible.
- Keep current data photos, date labels, and asset accessibility descriptions.
  This action inventory does not authorize replacing user content with symbols.
- Wording proposals coordinate with the existing product-vocabulary work in
  [#150](https://github.com/muhiro12/Cookle/issues/150).
- Publish only sanitized summaries and repository-relative source references.
  Private comparison artifacts, device/session identifiers, and raw logs do not
  belong in public Issues or tracked documentation.

## Verification of the Selected Refinements

- The current Cookle build succeeded with zero raw warnings or errors.
- Swift formatting and retained repository checks, including 28 script checks,
  passed. The Swift diff changes only titles and SF Symbol names.
- The three renamed catalog keys have translated values in all five supported
  languages. Catalog size remains 510 keys, with no incomplete or stale keys;
  unrelated review-only translation tasks remain unchanged. Untouched entries
  are identical to the previous revision, including placeholders and metadata.
- Live iPhone 18 Pro / iOS 27.2 checks use isolated in-memory sample data.
  Japanese screens cover new-form confirmation, editing in toolbar/content,
  duplication, last-opened navigation, tag browsing versus Sort, and bulk input.
  Japanese and English bulk-input labels display in full; their sheets retain
  accessible Cancel/Done meanings with native close/checkmark presentations.
- Settings import and the isolated conflict-review confirmation display the
  selected tray symbol. The disabled confirmation retains its Import
  accessibility name; Cancel closes the review without importing data.
- The conditional advertising-privacy entry and Preview-only suggestion are
  verified by source and build. N1's selected symbol is also source/build-only:
  the isolated cooking fixture does not persist the snapshot read by the list's
  return-target resolver. No live consent operation or suggestion entry point
  is claimed. No real data import, save/delete, model request, iPad or older-OS
  qualification, or spoken VoiceOver pass is claimed.

[decision]: ../Decisions/0013-preserve-semantic-adaptive-action-labels.md
