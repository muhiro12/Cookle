# ADR 0001: Adopt shared services and workflow adapters

- Status: Accepted
- Date: 2026-03-04

## Context

Cookle aims to stay close to Apple's preferred app architecture. The codebase is
built around `SwiftUI`, `SwiftData`, `Environment`, and `AppIntents` rather
than a custom layered framework.

At the same time, Cookle already has multiple targets and will likely grow more
over time. The iOS app, widgets, and future targets need to reuse the same
domain behavior without copying business logic into each target.

Before this decision, some user-facing flows had started to drift:

- views directly mutated SwiftData models
- App Intents sometimes owned their own command logic
- app-only side effects were mixed into UI components
- search logic risked diverging between UI and intents

That drift made the design harder to explain and weakened the shared-library
boundary.

## Decision

We will separate the system into shared services and target adapters.

### Shared core

`CookleLibrary` is the source of truth for shared business logic.

It owns:

- SwiftData models
- predicates and query helpers
- validation and mutation services
- migrations
- route helpers

### App adapter layer

The `Cookle` target owns adapter code for the main app.

It owns:

- SwiftUI views
- App Intents
- workflow services that orchestrate app-only follow-up
- notifications, widget reloads, review prompts, and app-only routing

### App Intents

App Intents are treated as system-facing adapters, not domain services.

They should:

- resolve parameters
- call a shared query service or workflow service
- return dialogs, values, snippets, or route actions

They should not:

- become the only implementation of a business action
- duplicate validation or mutation logic

### Workflow services

User-facing command flows in the app should go through workflow services such as
`RecipeActionService`, `DiaryActionService`, `TagActionService`, and
`SettingsActionService`.

These services wrap shared mutations and then run app-only side effects.

### Canonical search

`RecipeService.search` is the canonical recipe search implementation used by
views, intents, and widgets.

## Consequences

### Positive

- shared domain behavior is reusable across targets
- App Intents expose existing workflows instead of creating a parallel system
- app-only side effects have a single home
- the architecture is easier to explain and maintain
- future targets can add their own adapters without changing the shared core

### Negative

- the app target contains more thin orchestration types
- some flows require an extra hop through a workflow service
- engineers need to follow placement rules consistently to keep the boundary
  clean

## Rejected alternatives

### Put all behavior in SwiftUI views

Rejected because it does not scale across App Intents, widgets, or future
targets.

### Put all behavior in App Intents

Rejected because App Intents are a system-facing interface, not a good internal
API for normal app code.

### Introduce repositories and a larger clean architecture stack

Rejected because it adds abstraction without matching Cookle's current needs and
would move the code away from Apple's standard patterns.
