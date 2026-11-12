# Recipe text workflows

## Product scope

Recipe text input and content sharing serve separate journeys. Cookle accepts
ordinary pasted text and offers readable content for use in other apps. It does
not require a Cookle-specific Markdown template, companion AI prompt, exact
heading grammar, or format/schema version in this workflow.

This implements the direction checkpoint in [#164][input-issue], informed by
[Incomes #426][reference-issue], and the content-copy/share slice of
[#151][sharing-issue]. Broader drag/drop and transferable interactions remain
separate work. There was no implemented recipe template reader to retire.

## Input and review

On iOS 26 and later, Add Recipe and Recipe Tools offer Import from Text, Read
Recipe from Photo, and Import from Website. Each enters the existing text-review
surface and applies suggested fields to the ordinary unsaved Recipe form.
Output from an external AI uses Import from Text without a dedicated mode.
Manual entry remains available on the full supported OS baseline.

The existing extraction adapter uses the on-device Foundation Models model
when available and conservative deterministic extraction when unavailable.
A failed model request reports an error and keeps its source for retry. This
flow makes no external AI request. Creative PCC generation remains separate.
The extraction follow-up below evaluates text fidelity independently of OCR.

The open form owns the latest imported source text. Cancelling text assistance,
retrying after an error, and returning from a successful extraction retain that
text. Opening Import from Text again restores it, including website attribution
and structured grounding when the website text is unchanged. Successful new
photo recognition or website import replaces the source with the chosen text.
Editing or replacing retained text through Import from Text clears the previous
website attribution, so a new paste cannot inherit an unrelated source URL.
The form exposes Source Recipe Text as selectable literal text for comparison
with the suggested fields. It is editing-session state, excluded from the saved
Recipe and the device-local draft recovery snapshot.

Existing replacement confirmation, stale-result review, cancellation, and
one-step undo continue to protect entered fields and photos. Source text is not
an assertion that extraction preserved every fact. Review quantities, ordering,
servings, cooking time, ambiguous values, and attribution before saving. The
ordinary Create or Update action validates and saves through
`RecipeFormOperations`; applying suggestions alone does not save or change
Diary. Pasting a URL does not trigger a fetch; website fetching has its own
explicit flow.

## Output

Recipe actions and the Recipe list context menu offer Copy Recipe Content and
Share Recipe Content. Both use `RecipeOperations.contentText`, with localized
headings supplied by the app. The share action uses native `ShareLink` with a
String representation; copying writes the same text to the system pasteboard.

The text contains the name, known servings and cooking time in minutes, ordered
ingredient/amount rows, numbered steps, categories, and notes. Multiline content
and source links already present in notes stay literal. Categories have a stable
alphabetical order because the stored relationship has no user-defined order.
Unknown numeric values and absent sections are omitted. Photos, cooking history,
internal identifiers, and sync metadata are excluded.

This is readable text, not a lossless or versioned re-import contract. Recipe
link sharing continues to share a reference independently. Existing `.cookle`
portable-data export/import, identity, schema, and recovery behavior are
unchanged.

## Verification boundary

Library regression tests check text meaning, ordering, localization boundaries,
multiline content, unknown values, literal instruction-like text, and absence of
store mutations. Existing inference-application tests cover replacement, unknown
values, stale form edits, and undo. App build and focused UI verification cover
the native actions and source-text lifetime. These checks do not establish
on-device model accuracy, culinary correctness, or release qualification.

## Extraction evaluation and decisions

On 2026-11-12, eight fabricated inputs exercised the production extraction
adapter with the default on-device Foundation Models model, greedy sampling,
and the existing guided schema. The Xcode snippet host used the assigned
iOS 27.2 Simulator; availability reported `available`. This is Simulator/model
functional evidence, not physical-device timing or population accuracy.

The model retained ingredient/amount pairs and step order in all eight cases.
It omitted one labeled Japanese source URL and promoted a step's eight-minute
duration into the recipe's cooking time in another case. Some notes repeated
already extracted facts. Source preservation and explicit cooking metadata now
ground both model and fallback results deterministically; prompts and sampling
were not changed. Regression tests replay the two substantive failure modes.

Seven inputs also had explicit section/row structure usable without a model.
The table counts form field groups needing correction: name, servings, cooking
time, ingredient rows, step rows, and note facts. Each affected group counts
once regardless of row count. This estimates correction scope, not editing
time, taps, or user-study results. Formatting-only differences do not count.

| Synthetic shape | Before | After |
| --- | ---: | ---: |
| English labels, amounts, notes and source | 4 | 0 |
| Japanese Markdown bullets and source | 4 | 0 |
| Rendered text with trailing quantities and step time | 2 | 0 |
| Ambiguous servings and cooking-time ranges | 1 | 0 |
| Two-column Markdown ingredient table | 2 | 0 |
| Numbered steps with indented continuation lines | 3 | 0 |
| French ingredient and step headings | 2 | 0 |

Before counts come from the captured production fallback outputs. After counts
come from the same inputs asserted against source-based expectations in
`RecipeExtractionQualityTests`. The French case previously could not produce
a meaningful draft, so its before count describes missing groups, not a
previously available editing screen. The eighth input was ordinary prose:
the model extracted it, while the fallback still declines to invent structure.

The fallback now separates explicit colon-delimited pairs and recognized
trailing quantities without changing units. Unitless or ambiguous forms remain
literal. It recognizes common headings in the five supported app languages,
keeps notes and attribution out of steps, recognizes labeled two-column
ingredient tables, and joins indented continuation lines to their step.
Unknown table shapes remain literal rather than losing unrecognized columns.

Cooking time requires recipe-level cooking metadata. Preparation time,
ready-in time, and individual step durations do not populate that field.
Unsupported explicit durations remain in notes, including mixed hour/minute
or fractional values. Ranges remain unknown numerically with their source
wording retained. Labeled source text is preserved even if a model omits it.

A full post-change model batch timed out, and the narrower retry reported
that the Preview service was no longer running. These are tool/probe limits,
not a successful model rerun or evidence that the model became unavailable.
The deterministic corrections have regression coverage; wider model repeats,
OCR, physical devices, and measured human editing time remain separate work.
The small corpus does not justify a dedicated exact-transfer template or a
claim that arbitrary recipes need no correction. Manual review remains required.

[input-issue]: https://github.com/muhiro12/Cookle/issues/164
[reference-issue]: https://github.com/muhiro12/Incomes/issues/426
[sharing-issue]: https://github.com/muhiro12/Cookle/issues/151
