# ADR 0013: Preserve Semantic, Adaptive Action Labels

- Status: Accepted
- Date: 2026-10-25
- Tracking: [#163](https://github.com/muhiro12/Cookle/issues/163)

## Context

Cookle reuses actions in toolbars, content, sheets, and context menus. Different
creation actions can appear beside each other, so a shared symbol must identify
the action across all of those placements.

The history contains separate changes to symbols and presentation:

- `ea3d07b2` distinguished recipe creation (`book.pages`) from Diary creation
  (`book`). `cb34ee6b` retained titles and symbols in explicit `Label` values.
- `eafde75a` changed both creation symbols to `plus`; the semantic labels
  themselves remained. A common addition symbol is recognizable within a list,
  but it cannot distinguish adjacent recipe and Diary creation actions.
- `12ee794e` introduced a text-only `showsTitle` path to clarify that the Photos
  entry created a recipe. `4c7cd9f2` later used that path in the Diary toolbar.
- `50c48705` restored the semantic labels and distinct object symbols.
  `ff8786ca` aligned reusable app actions, including cancellation, completion,
  import, and equivalent button/menu labels.

Replacing a label with plain text solves one presentation at the cost of
removing the symbol available to other native presentations. Conversely, a
label's automatic presentation cannot decide whether its supplied symbol
communicates the intended operation.

## Decision

- Reusable actions own a localized semantic title and an appropriate SF Symbol
  through `Label`, including controls built with native title/symbol
  initializers.
- Native containers choose whether to show the title, symbol, or both. A local
  style override needs a concrete layout or information reason. It must not be
  the first workaround for an ambiguous shared symbol.
- Review all call sites and adjacent actions before changing a shared symbol.
  Test the combination of actions, not only each symbol in isolation.
- Adopt creation option C: recipe creation uses `book.pages`; Diary creation
  uses `square.and.pencil`. Keep `book.badge.plus` for adding an existing recipe
  to today's Diary. The Diary navigation tab retains its separate `book` symbol.
- Share `CancelButton`, `DoneButton`, and `ImportDataButton` labels where their
  meanings match. Keep action callbacks, disabled state, draft confirmation,
  and task cancellation with their owning screens.
- A normal button and a context-menu submenu can share a label without sharing
  presentation lifetime. Keep the separate Diary-add flows and their existing
  error handling.
- Retain native dialog roles and information-bearing controls such as timer
  values. Reusable action labels do not require turning every text or image
  into an icon-only control.

## Consequences

Creation remains distinguishable when the two entries appear together. Titles
remain available to accessibility and expanded/menu presentations, and the app
does not maintain manual OS-specific text/icon rendering branches.

Object symbols alone can resemble navigation. The selected Diary compose symbol
strengthens the creation meaning while retaining the established recipe symbol.
Further symbol and wording choices remain proposals in the
[action-label options](../Plans/action-label-symbol-options.md); they are not
permission for an automatic app-wide replacement.

This decision preserves current import, AI draft, save, cancellation,
persistence, and navigation behavior. It does not restore obsolete saving
components or change stored data, routes, or supported OS versions.

## Verification

Build the affected app and run the repository's formatting and retained checks.
Inspect adjacent creation actions in a live native toolbar, their semantic
accessibility labels, and entry/cancel navigation. For shared controls, retain
representative content/menu, unsaved-confirmation, and sheet evidence. A symbol
comparison rendered with macOS SF Symbols is design evidence, not an iOS runtime
capture or proof of older-OS, iPad, or spoken VoiceOver behavior.

## Platform Basis

- [SwiftUI Label](https://developer.apple.com/documentation/swiftui/label)
- [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
