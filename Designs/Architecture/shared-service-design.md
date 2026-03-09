# Shared Service Design

This document is the current source of truth for how shared logic is organized
in Cookle. It records the stable placement rules. Historical decisions and
tradeoffs live in [`Designs/Decisions/`](../Decisions/).

## Goal

Cookle follows Apple-first application design while keeping shared logic
reusable across multiple targets such as the iOS app, widgets, and future
targets.

The design should keep these constraints in balance:

- Stay close to `SwiftUI`, `SwiftData`, `Environment`, and `AppIntents`.
- Avoid large abstraction layers such as repository-driven clean architecture.
- Keep reusable business logic in a shared package.
- Keep target-specific side effects out of the shared package.

## Layers

### 1. Shared core: `CookleLibrary`

`CookleLibrary` is the source of truth for shared business logic.

Put these concerns in `CookleLibrary`:

- SwiftData models such as `Recipe`, `Diary`, `Ingredient`, and `Category`
- Predicates, queries, and route helpers
- Validation and mutation services such as `RecipeService`, `DiaryService`, and
  `TagService`
- Migrations and storage helpers
- Logic that should work the same way for the app, widgets, App Intents, and
  future targets

Do not put these concerns in `CookleLibrary`:

- `WidgetCenter` reloads
- local notifications and scheduling
- review prompts
- app-only route pipeline orchestration
- sheet dismissal, focus control, or other transient UI state
- `openURL` or other target-owned side effects

### 2. App adapters: `Cookle`

The `Cookle` app target owns adapters and orchestration.

Put these concerns in `Cookle`:

- SwiftUI screens and local presentation state
- platform environment factory, runtime bootstrap, and environment wiring
- runtime lifecycle plans for launch and foreground refresh
- App Intents
- workflow services such as `RecipeActionService`, `DiaryActionService`,
  `TagActionService`, and `SettingsActionService`
- notification synchronization
- review prompting
- widget reload coordination
- app-only routing and environment wiring

Workflow services are the bridge between shared mutations and app-only side
effects.

The root platform environment factory should prefer `MHAppRuntimeBootstrap` and
`MHAppRoutePipeline` over hand-written route-drain orchestration, but
success-triggered follow-up work such as review prompting should still
originate from workflow services instead of generic foreground handlers.

### 3. Other target adapters: `Widgets` and future targets

Other targets should use `CookleLibrary` directly for shared queries and
mutations.

If a target needs its own side effects, add a target-local adapter for that
target instead of pulling app-specific behavior into `CookleLibrary` or reusing
the `Cookle` app adapter layer.

## App Intent position

App Intents are adapters, not domain services.

Use App Intents to:

- expose durable user actions to the system
- resolve parameters and entities
- return dialogs, values, and snippet views
- open route-based destinations

Do not use App Intents to:

- own the mutation logic itself
- become the only caller of a domain workflow
- duplicate search or validation rules that already exist in `CookleLibrary`

The preferred shape is:

1. resolve parameters in the App Intent
2. call a shared query service or app workflow service
3. return the result

## What views may own

Views may own:

- local form state
- focus state
- sheet and navigation presentation
- lightweight formatting for display
- triggering a workflow service or route action

Views should not own:

- direct model deletion for user-facing flows
- direct model updates for user-facing flows
- cross-target side effects
- default-setting normalization or notification rescheduling logic
- duplicated validation rules
- canonical search behavior

## Placement rules for new features

Use these questions when adding new code:

1. Should this logic behave the same way in the app, widgets, and App Intents?
   If yes, start in `CookleLibrary`.
2. Does this logic talk to notifications, review prompts, widget reloads, or
   app-only routing? If yes, place it in an app workflow service.
3. Is this only presentation state for a single screen? If yes, keep it in the
   view.
4. Is this a system-exposed action? If yes, add an App Intent that wraps the
   existing service or workflow.

## Canonical rules

- `RecipeService.search` is the canonical recipe search API.
- User-facing command flows should go through workflow services, not direct
  model mutation from views or App Intents.
- Route parsing and route execution stay shared so app, widgets, and App
  Intents use the same navigation vocabulary.
- Route ingestion should flow through a single `MHAppRoutePipeline` so
  notifications, universal links, and App Intents do not diverge.
- Review prompting should be attached to successful user-facing workflows rather
  than app foreground events.

## Anti-patterns

Avoid these patterns:

- a SwiftUI button directly calling `model.delete()` for a normal user action
- an App Intent containing its own copy of create, update, or delete logic
- widget reloads or notification sync inside `CookleLibrary`
- multiple independent implementations of recipe search
- adding repositories or protocol-heavy persistence abstractions without a
  concrete need

## Example

Recipe creation should flow like this:

1. a SwiftUI view or App Intent builds `RecipeFormDraft`
2. `RecipeActionService` calls `RecipeFormService`
3. `RecipeActionService` performs app-only follow-up such as widget reload and
   notification sync
4. the caller updates presentation state or returns an intent result
