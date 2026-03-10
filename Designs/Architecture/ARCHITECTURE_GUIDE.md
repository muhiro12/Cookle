# Cookle Architecture Guide

## Scope

This guide defines the strict `domain-in-library, adapters-in-targets` policy
for this repository.

Related documents:

- [shared-service-design.md](./shared-service-design.md)
- [ADR 0001](../Decisions/0001-adopt-shared-services-and-workflow-adapters.md)

## Responsibility Boundaries

| Layer | Owns | Must not own |
| --- | --- | --- |
| Domain (`CookleLibrary`) | SwiftData schema, predicates, route helpers, validation, canonical mutations, canonical search, migration helpers, domain-side mutation effect hints | Widget reloads, notification registration, review prompts, app lifecycle wiring, SwiftUI presentation state |
| Adapter (`Cookle`, `Widgets`, App Intents) | Parameter parsing, platform API calls, dependency wiring, route intake, widget timelines, follow-up orchestration after shared mutations | Duplicated business branching that should live in `CookleLibrary` |
| View (SwiftUI) | Focus state, sheets, navigation state, transient view state, display formatting, composition | Direct user-facing mutations, canonical search branching, notification synchronization, review or widget side effects |

## View Rules

Allowed in views:

- Focus and keyboard behavior
- Sheet, alert, and navigation state
- Display formatting and layout composition
- Triggering an action service or route action

Not allowed in views:

- Reimplementing recipe, diary, or tag mutation rules
- Owning the canonical recipe search behavior
- Scheduling notifications or reloading widgets directly
- Attaching review prompts to ad hoc UI event paths

## Canonical Mutation Flow

User-facing command flows should follow this path:

`View or App Intent -> action service or adapter -> CookleLibrary service -> MutationOutcome<Value> -> app-side follow-up`

In practice, the current adapter anchors are:

- `Cookle/Sources/Recipe/Services/RecipeActionService.swift`
- `Cookle/Sources/Diary/Services/DiaryActionService.swift`
- `Cookle/Sources/Tag/Services/TagActionService.swift`
- `Cookle/Sources/Settings/Services/SettingsActionService.swift`
- `Cookle/Sources/Common/Services/CookleMutationEffectAdapter.swift`

Those adapters may coordinate widget reloads, notification refreshes, and
review prompting after a shared mutation succeeds, but the mutation rules
themselves belong in `CookleLibrary`.

## App Intent Mapping

App Intents must follow the same domain path:

`App Intent parameter parsing -> shared query service or action service -> same CookleLibrary APIs`

Intent files may:

- resolve entities and parameters
- map domain errors into intent-facing results
- open route-based destinations

Intent files must not:

- become the only implementation of a user-facing mutation
- duplicate validation, search, or mutation branching from `CookleLibrary`

## Mutation Effect Contract

Shared mutations should express follow-up hints through
`CookleLibrary/Sources/Common/MutationOutcome.swift` and
`CookleLibrary/Sources/Common/MutationEffect.swift`.

Current effect hints are:

- `recipeDataChanged`
- `diaryDataChanged`
- `notificationPlanChanged`
- `reviewPromptEligible`

Adapters decide which platform actions to run from those hints. The current
translation point is
`Cookle/Sources/Common/Services/CookleMutationEffectAdapter.swift`.

## SwiftData Boundary

Keep in `CookleLibrary`:

- `@Model` types
- predicates and shared query helpers
- domain mutation and validation services
- migration plans and persistence-neutral helpers

Keep in target adapters:

- `ModelContainer` construction
- iCloud enablement policy
- `MHAppRuntimeBootstrap` and `MHAppRoutePipeline` assembly
- `UNUserNotificationCenter` integration
- WidgetKit reload coordination
- review prompt orchestration

## Default Refactoring Rule

When logic is reused or should behave the same across the app, widgets, and App
Intents, the default fix is to move it toward `CookleLibrary`.

When logic is still platform glue, the default fix is to keep it in a target
adapter, usually under `Cookle/Sources/Common/Platform/` or a feature-local
`Services/` directory in `Cookle/`.
