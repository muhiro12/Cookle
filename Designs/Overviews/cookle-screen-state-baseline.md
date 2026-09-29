# Cookle Screen State Baseline

Observed September 21–22, 2026.

## Purpose

An annotated baseline of Cookle's screens in empty, populated, and error states,
recorded so that https://github.com/muhiro12/Cookle/issues/110 can separate
**what was observed** from **what is still a hypothesis**. That separation is
the first acceptance item on that issue, and it is the thing the earlier
planning passes said was missing.

This note proposes no hierarchy, no layout, and no visual acceptance criteria.
Those are the later items on that issue and they are decisions.

Environment: iPhone 18 Pro (402x874 pt) and iPad 11" (834x1210 pt), both
iOS 27.0, Japanese locale. Populated states use the app's own capture fixtures
(`COOKLE_CAPTURE_MODE=1`), which load five recipes, ten diaries, and ten photos
into a store separate from the live one. Sample photos were not supplied
locally, so those fixtures render SF Symbol placeholders rather than
photographs; where that matters it is said so.

## 1) Observed — confirmed by interaction

### Empty states render an action, and it stays reachable

Diary and Recipes on a fresh install both present a `ContentUnavailableView`
with a primary action. In a 366x345 pt window the Recipes card clips below the
fold, but the column scrolls and "Add Recipe" is reachable. Clipping at that
height is adaptive behavior, not a defect.

### Split-view columns explain themselves

Previously a wide iPad could render a blank half-screen, because a
`NavigationSplitView` that cannot seat every column drops the sidebar and leaves
a conditionally empty column visible. Both the content and the detail columns
now carry `SplitContentPlaceholder`. Fixed in `944161bd`, `3348276b`,
`a1d00c7c`.

### Populated states hold together

Diary detail with five meals across three meal types renders section headings
with two-line recipe summaries. Recipe list with five recipes, recipe detail
with photo, serving size, cooking time, primary actions, ingredients, steps,
sharing, and management. Nothing truncates into unreadability.

### Content scrolls clear of the floating tab bar

Mid-scroll, recipe detail content passes under the tab bar, which is the iOS 26+
presentation. At the bottom of the scroll the last rows sit fully above it with
clear space, so the bottom inset is correct.

### An error state is handled correctly

A cooking session whose recipe no longer exists is the most interesting state
found. `CookingSessionSnapshot` is self-contained — it carries the recipe name
and the step text — so the session still opens and its steps and timers still
work, which is the right call for someone who is mid-cook.

Choosing **End and add to diary** then produces a clear alert — the diary
cannot be opened because the recipe was not found — and leaves the session
snapshot intact. Nothing fails silently, nothing is lost, and the wording names the
actual cause. Recorded because an audit should record what works, not only what
does not.

### Destructive text contrast

3.52:1 in default light appearance, below the 4.5:1 that applies at this text
size. Every other condition clears. Measured and tabulated in
[the MHUI rollout record](../Plans/mhui-app-rollout.md).

## 2) Observed — characteristics that need a decision, not a test

### The photo grid does not normalise tile aspect ratio

`PhotoListView` uses `LazyVGrid` with `.adaptive(minimum:)` columns, and
`CooklePhotoImage` renders a loaded photo with `.resizable().scaledToFit()`. A
tile therefore takes its own image's aspect, so a row of a landscape and a
portrait photo produces mismatched heights and visible gaps.

The capture fixtures exaggerate this, because SF Symbol placeholders have
unusual aspects. But real photographs vary too, so the raggedness is a property
of the layout rather than of the fixtures. Whether to keep it or move to the
conventional filled square grid is a design decision and belongs to the issue.

## 3) Still hypotheses

- **Whether the observed hierarchy is the wrong hierarchy.** Everything above is
  about whether screens render and behave correctly. The concern that started
  issue 110 — that the UI resembles the data schema too directly — is a
  judgment about information architecture, and nothing here confirms or refutes
  it.
- **VoiceOver.** Not exercised. It cannot be driven from this environment
  without taking over touch input.
- **Real photographs in the grid and in recipe detail.** Only placeholder assets
  were rendered.
- **Error states other than the one above.** Invalid data import, a full
  disk, and model unavailability have deterministic library coverage but were
  not exercised as screens.
