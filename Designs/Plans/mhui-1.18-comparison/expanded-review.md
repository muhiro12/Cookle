# Expanded MHUI Recipe Detail Review

> Expanded direction accepted on September 14, 2026. The comparison findings
> below remain capture-time evidence. See [adoption status](adoption-status.md)
> for the production-source implementation and current verification.

## What This Option Tests

The [three-way gallery](three-way-comparison.md) compares the current screen,
the earlier minimum MHUI treatment, and a composition using more MHUI APIs.
Both candidates use the full MHUI 1.18 product. The difference is how much
screen composition the app assigns to the package.

The expanded option retains the same recipe title, nine existing content
sections, conditions, ordering, values, dates, step numbering, and six actions.
It adds no summary, feature grid, new wording, duplicated title, floating bar,
or diary-list redesign. The navigation title and toolbar remain native.

<!-- markdownlint-disable MD013 -->
| Responsibility | Minimum candidate | Expanded candidate |
| --- | --- | --- |
| Root theme and product | MHUI 1.18, `mhTheme(.standard)` | Identical |
| Screen scrolling | Native List with `mhListChrome` | VStack in `mhScreen`, which owns the ScrollView, margins, and readable width |
| Content sections | Native groups with seven MHUI headers | Nine `mhSection` groups, including the two existing timestamp sections |
| Rows | Native List rows | `MHGroupedRows` with package-owned row spacing and separators |
| Ingredients | Existing horizontal label/value row | `mhKeyValue`, with adaptive horizontal or stacked label/value layout |
| Action area | Existing native action rows | Vertical `MHActionGroup`; cooking primary, ordinary actions secondary, delete destructive |
| Explanatory footer | Native List footer | Same text through `MHSectionFooter` |
| Data, routes, sheets, confirmations | Existing implementation | Same handlers and native presentations |
<!-- markdownlint-enable MD013 -->

MHUI 1.18 documents both native-container and signature-composition paths.
This recipe detail has no selection, swipe action, reordering, or List editing
to transfer in the reviewed slice. That makes a stack-based comparison
reasonable. It does not justify converting collection lists or native Forms
across Cookle. Current Stally remains evidence for the native-container route;
this expanded Cookle rendering is its own evidence.

## Source and Reproduction

The [expanded patch](recipe-detail-expanded.patch) is an alternative to the
earlier [minimum patch](recipe-detail-candidate.patch), based on the same
Cookle commit `0a9eda1be5b24217ad69082f5862d406051e8248`. Do not apply both.
The expanded patch is now the production adoption basis, accompanied by
ADR 0009, the 1.18 minimum requirement, and updated boundary checks. The stored
patch remains a historical input and must not be reapplied to adopted main.

The expanded patch changes 13 app Swift files and the same app product
reference. Two small app-owned presentation helpers let Recipe Detail choose
the composed section treatment while other consumers retain native sections
by default. This matters because Search results and App Intent snippets reuse
ingredient and step components. Their call sites and native content are not
converted to the stack treatment.

The helper controls presentation only. Ingredient/category/diary navigation,
recipe opening, cooking state transitions, and all existing action button
implementations remain unchanged. No logic is extracted to MHUI or moved into
CookleLibrary.

Use the same [capture fixture](capture-fixture.patch) and launch controls in
the [reproduction instructions](README.md). Apply the expanded implementation
patch excluding its CookleApp.swift change, then add the standard MHUI import
and root theme to the fixture entry. The fixture, package revision, root theme,
and project settings are identical between the two MHUI captures.

## Visual Tradeoffs

The expanded light rendering is visibly different: bounded section surfaces,
larger vertical gaps, and a fixed label/value reading rhythm replace native
grouped-list geometry. The first viewport contains four complete ingredient
rows, compared with six in both earlier standard-size captures. The remaining
ingredients are below the fold, not removed.

In the reading region, inset surfaces narrow the text measure. The same step
sentences wrap onto more lines, and the same note is preserved with different
line breaks. The lower action area clearly differentiates the existing cooking
entry from ordinary actions and deletion. The toolbar's edit control remains
unchanged; no action is moved to a floating overlay.

Dark appearance retains the same hierarchy with dark solid content surfaces
and distinct action treatments. At accessibility size 1, each ingredient name
and quantity stacks vertically. The first viewport shows one complete
ingredient and the beginning of the next, so this option has a substantial
scrolling cost even though the visible text remains readable.

The additional large-text action capture preserves all six labels, with the
long edit, duplicate, and delete labels wrapping onto two lines. No overlap or
cut-off label was observed. Dark destructive text is visibly less prominent
than the white secondary labels; it was readable by inspection, but numerical
contrast and Increase Contrast behavior have not been certified.

The package's standard colors and metrics are unchanged. This is a comparison
of its published treatments, with no local token adjustment made to compress
the result. A denser or mixed treatment would be another candidate to render
and approve, rather than an implicit replacement for the images shown here.

## Historical Comparison Verification

- The isolated expanded build and native run succeeded with the same MHUI
  1.18 revision and Xcode 27.0 (`27A266a`) used for the earlier comparison.
- Eight original expanded screenshots are retained: six comparable viewports
  and additional dark/large-text action checks. The twelve earlier originals
  remain unchanged.
- The expanded patch passes `git apply --check` against baseline `0a9eda1`. A
  separate disposable source copy with only this product patch passes the
  repository SwiftLint task, including both new helper files.
- The common capture fixture has five lint violations in its temporary app
  entry, fixed-date literal, and Preview declaration. They predate the expanded
  treatment and are excluded from the product patch. Formatting passed; this
  does not make the complete capture fixture lint-clean.
- At capture time, main passed the retained repository rules under its
  metrics-only package boundary and excluded-surface checks.
- The existing edit sheet opened from the styled action and returned with
  Cancel. Its native fields and toolbar controls retained their appearance;
  no visible secondary-action style leakage was observed. Cooking opened at
  step 1 of 6 and Close returned with Resume Cooking.
- The existing delete confirmation opened and was dismissed without deletion.
  No save, share submission, diary insertion, duplicate, timer, or cooking
  completion was executed.
- All five comparison Markdown files pass markdownlint, artifact links resolve,
  and `git diff --check` passes. The twelve earlier screenshot hashes match
  their retained ledger.
- The run and interaction session are stopped. The temporary project's scheme
  and destination were restored before closing it, and only the dedicated
  comparison simulator was shut down. The main Xcode selection is unchanged.

These are bounded UI observations. They do not establish production bootstrap,
CloudKit, data persistence, or release readiness. The common fixture's existing
NoAccount and simulator warnings remain qualifications of the capture setup.

## Adoption Implications

The [original adoption review](../mhui-1.18-adoption-review.md) still defines
the release sequence and required ADR, documentation, and boundary checks.
This larger option does not require additional target dependencies, changes
to deployment support, or any CookleLibrary, Watch, or Widgets changes.

ADR 0009 now names the selected stack-based Recipe Detail boundary and the
native defaults for its shared section consumers. It does not turn signature
composition into a blanket rule for lists, search results, App Intent snippets,
or Forms.

The larger replacement needs more verification than a canvas/header change:

- Check scroll restoration, hit regions, action labels, accessibility focus,
  and long recipe/diary histories after leaving List's native row management.
- Check compact and regular widths, long translations, and large text. The
  adaptive ingredient layout deliberately permits stacked values.
- Check the real photo and advertising states. Their source components remain
  present, but List-specific row modifiers cannot establish their appearance
  inside the new screen container.
- Retain all existing destructive confirmations, disabled states, and route
  behavior. Do not introduce data or navigation changes to compensate for a
  presentation preference.

The existing no-MHUI/no-MHDesign restrictions for CookleLibrary, Watch, and
Widgets, and the main-target App Intent import guard, remain part
of the adoption change set. Presentation helper defaults do not authorize
behavior adapters to import presentation packages.
