# ADR 0006: Prefer loss-tolerant preferences and authoritative SwiftData

- Date: 2026-04-12
- Status: Accepted

## Context

Cookle persists two very different kinds of information.

The first kind is user-owned product data: recipes, diaries, photos, tags, and
their ordered sub-objects. That data is part of the product itself and already
lives in `SwiftData`.

The second kind is lightweight runtime or preference-style state: UI flags,
small numeric settings, cross-target route handoff, diagnostic snapshots, and
draft assistance. That data currently lives in descriptor-backed
`AppStorage` / `UserDefaults`.

Cookle now runs `CooklePreferenceLifecycle` during startup. That lifecycle
keeps only the declared app-owned descriptors in the app-owned standard domain
and app-group shared suite, and removes unknown keys from those domains.

That cleanup model is useful because it keeps preferences auditable and
prevents stale keys from accumulating. It also means preference-backed state is
only safe when the product can tolerate loss unless a migration explicitly
rescues the old data.

## Decision

Cookle adopts the following persistence policy.

### AppStorage is the first choice for preference-style state

When SwiftUI needs lightweight preference-style persistence, prefer
`AppStorage`.

`UserDefaults` remains the underlying storage mechanism, but app code should
not scatter raw `UserDefaults` access. Use descriptor-backed access through
`AppStorage`, `MHPreferenceStore`, `CooklePreferences`, or
`CookleSharedPreferences`.

### AppStorage and UserDefaults may store only loss-tolerant state

Data stored in `AppStorage` or app-owned `UserDefaults` must be:

- non-authoritative
- recomputable or replaceable
- acceptable to lose during cleanup, reset, or key retirement

This is a strong default, not a hard rule. Exceptions are possible, but they
must be justified explicitly and reviewed as design decisions rather than added
casually.

### SwiftData is the home for authoritative user data

If losing a value would materially harm the user, create inconsistency, or
discard information that the product treats as important, that value should not
live only in `AppStorage` or `UserDefaults`.

That kind of data belongs in `SwiftData`.

## Examples

### Allowed preference-style examples

These are acceptable in `AppStorage` / `UserDefaults` because they are
loss-tolerant:

- debug and product-control flags
- daily notification toggle and selected notification time
- last launched app version
- last opened recipe pointer
- pending route handoff between App Intents and the app
- diagnostic logging snapshots
- create-flow draft-assistance snapshots

### Disallowed examples

These should live in `SwiftData`, not in `AppStorage` / `UserDefaults`:

- recipe, diary, photo, category, and ingredient records
- ordered recipe and diary sub-objects
- authoritative user history or content
- any future setting whose loss would meaningfully damage the user experience
  or create inconsistent product state

## Cleanup implications

App-owned preference storage is intentionally declarative: only the descriptors
that Cookle currently declares are expected to survive cleanup.

Because of that, old keys are not automatically rescued. Recent retired keys
that are intentionally allowed to disappear include:

- `pendingCookleIntentDeepLinkURL`, because it was only a temporary route queue
- `cookle.logging.last-session.current-session` and
  `cookle.logging.last-session.previous-session`, because they were diagnostic
  snapshots
- `cookle.formSnapshot.diary` and `cookle.formSnapshot.recipe`, because they
  were draft-assistance snapshots for an unshipped snapshot design
- `cookle.preferences.lifecycle-state`, because it was internal bookkeeping
- legacy standard-domain `lastOpenedRecipeID`, because it was only a low-value
  last-opened pointer

This cleanup contract applies to Cookle's app-owned standard domain and
app-group shared suite. It does not apply to system-owned domains or to the
SwiftData store.

## Consequences

### Positive

- preference usage stays auditable because the surviving key set is explicit
- stale or forgotten app-owned keys do not accumulate indefinitely
- engineers have a clearer bar for deciding whether data belongs in
  `AppStorage` / `UserDefaults` or `SwiftData`
- the app avoids turning `UserDefaults` into a second product database

### Negative

- some low-value state may be lost when a key is intentionally retired
- engineers must think about loss tolerance up front instead of adding new
  preference storage casually
- exceptions need explicit reasoning, which adds a small design cost
