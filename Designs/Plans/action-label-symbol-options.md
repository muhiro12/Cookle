# Action Label and Symbol Options

- Date: 2026-10-25
- Status: Proposals except the accepted creation pair C
- Tracking: [#163](https://github.com/muhiro12/Cookle/issues/163)
- Decision: [ADR 0013][decision]

## Accepted Baseline

Recipe creation uses `book.pages`; Diary creation uses `square.and.pencil`.
Adding an existing recipe to today's Diary retains `book.badge.plus`. These are
distinct operations, even when creation and Diary actions appear together.

The shared-control audit covered 23 button types. Reusable cancellation appears
in nine placements, completion in four, and import confirmation in two. Existing
edit/delete/duplicate behavior and destructive confirmations remain intact.

## How to Review the Remaining Options

The rows below are candidates, not selected changes. A recommendation to retain
a symbol is a valid outcome. Select symbols and wording independently; the table
does not require changing both together. Wording examples describe intent and
are not final localized strings. Preserve interpolated object names where they
help identify the target, then review every supported language after selection.

Compare both icon-only and title-plus-icon contexts, adjacent actions, toolbar
overflow, Dynamic Type, and navigation versus content actions. Check selected
symbols against the actual deployment target. A border built into a symbol can
duplicate the native toolbar container. Distinguish creating an object,
applying form input, adding a relationship, and saving persisted data.

<!-- markdownlint-disable MD013 -->

## Basic Actions

| ID | Family and current symbol | Candidate | Assessment |
| --- | --- | --- | --- |
| B1 | Edit Recipe, Diary, and Tag: `pencil` | `pencil.line`; wording such as "Edit Content" where appropriate | Retain `pencil` by default. The line variant emphasizes editing text but is less general for photos and other fields. Keep `square.and.pencil` distinct as the Diary creation entry. |
| B2 | Delete Recipe, Diary, Photo, Ingredient, and Category: `trash` | `trash.fill` | Retain the outline for consistency. Fill is a weight/emphasis choice, not a different operation. Do not use an unlink or minus symbol for destructive deletion. |
| B3 | Duplicate Recipe: `document.on.document` | `plus.square.on.square`; "Duplicate and Edit" | The document stack conveys duplication well. The plus-square variant emphasizes creating another item but weakens the recipe-document connection. The wording can clarify that an editable copy opens before saving. |
| B4 | Close: `xmark` | `xmark.circle` | Retain `xmark`. The circle can create a double border in native toolbars; it is not an improvement merely because the old implementation used a circled symbol. |
| B5 | Cancel: `xmark` and "Cancel" | Keep the symbol; a contextual title such as "Cancel Editing" | Retain the generic title for the shared control. A more specific title is a placement-level wording proposal, not a reason to replace cancellation callbacks or their confirmation policy. |
| B6 | Done: `checkmark` and "Done" | Keep the symbol; "Apply" in selection or bulk-input contexts | Retain the checkmark. "Apply" may clarify changes to the parent draft, but does not fit simply leaving reorder mode. Never imply that all Done actions persist a recipe or Diary. |
| B7 | Import confirmation: `square.and.arrow.down` | `tray.and.arrow.down`; "Import Data" | Both communicate incoming data. The tray variant emphasizes intake. Preserve the distinct review and actual-import stages and all disabled/error states. |
| B8 | Recipe link sharing: `link` | `square.and.arrow.up`; "Save Recipe Link" | The share symbol matches the native sheet operation; `link` emphasizes the payload. The current footer explains that this is a reference for reopening Cookle, not sharing recipe contents, so keeping `link` is reasonable. A Save title must not imply an automatic save. |

## Content and Form Actions

| ID | Family and current symbol | Candidate | Assessment |
| --- | --- | --- | --- |
| F1 | Add existing recipe to today's Diary, button and submenu: `book.badge.plus` | `calendar.badge.plus`; "Add to Today's Meal" | Retain the book-plus by default. A calendar emphasizes the date but may suggest scheduling rather than recording food. Keep this separate from creating a new Diary. |
| F2 | Merge duplicate Tags: `arrow.triangle.merge` | `arrow.merge`; "Review Duplicates" | These names render alike in the current comparison; this is primarily a wording option, not a reason for symbol-name churn. A review title must not imply automatic normalization or change which saved Tag is kept. |
| F3 | Bulk ingredients: `list.bullet` | `list.bullet.rectangle`; "Enter Ingredients Together" | The rectangle suggests a separate list editor. The wording may describe editing the whole input more accurately than simply adding more rows. Keep it distinguishable from bulk steps. |
| F4 | Bulk steps: `list.number` | `text.alignleft`; "Enter Steps Together" | Retain numbered-list semantics by default. The text variant emphasizes multiline entry but loses the ordered-step meaning. |
| F5 | Advertising privacy options: `hand.raised` | `lock.shield`; "Ad Privacy Options" | Retain the hand by default. A shield can imply account/security protection. The more specific wording may distinguish this SDK entry from app-wide privacy policy or permissions. |
| F6 | Form confirmation: new `plus`, existing `checkmark` | `checkmark` for both; retain Create/Update titles | This would emphasize confirming input consistently. It is an unselected proposal; the current creation/update titles, saving behavior, and role availability remain unchanged. |

## Contextual Navigation and Assistance

| ID | Family and current symbol | Candidate | Assessment |
| --- | --- | --- | --- |
| N1 | Resume Cooking: `fork.knife.circle` | `play`; "Continue Cooking" | Play communicates resuming an activity; the current symbol identifies cooking. Prefer an unbordered symbol in a toolbar, then judge the content-row presentation separately. |
| N2 | Back to Last Opened: `arrow.uturn.backward.circle` | `clock.arrow.circlepath`; "Open Previous Recipe" | History can be clearer than an arrow that might suggest undo. The action must remain opening a recipe, not changing saved data. |
| N3 | Diary top suggestion: `sparkles` | `lightbulb`; a title that explicitly opens a Diary draft | The lightbulb emphasizes a suggestion without implying AI. This component currently has a Preview but no live call site; selecting a symbol does not authorize adding it to a screen. |
| N4 | Browse Tags menu: `line.3.horizontal.decrease` | `tag`; "Ingredients and Categories" | A tag identifies the actual destinations more directly; the current symbol resembles filtering. Compare with Sort to ensure the two menus remain distinguishable. |
| N5 | Recipe Tools menu: `wand.and.stars` | `doc.text`; "Recipe Input Tools" | The current symbol accommodates assisted editing. A document emphasizes text intake but underrepresents generation. Consider the whole menu's contents before choosing. |
| N6 | Sort: `arrow.up.arrow.down` | `arrow.up.arrow.down.circle` | Retain the unbordered arrows by default. The circled variant can duplicate the native container. Keep sorting distinct from tag browsing/filter-like actions. |

<!-- markdownlint-enable MD013 -->

## Boundaries

- No remaining row is approved for implementation solely by appearing here.
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

[decision]: ../Decisions/0013-preserve-semantic-adaptive-action-labels.md
