# Cookle Architecture Guide

## Scope

This guide defines the strict `domain-in-library, adapters-in-targets`
architecture for Cookle.

Related documents:

- [shared-service-design.md](./shared-service-design.md)
- [ADR 0001](../Decisions/0001-adopt-shared-services-and-workflow-adapters.md)
- [ADR 0002](../Decisions/0002-app-intents-are-adapters.md)
- [ADR 0003](../Decisions/0003-platform-adapters-stay-in-app-target.md)
- [ADR 0004](../Decisions/0004-views-own-presentation-and-screen-models.md)
- [ADR 0005](../Decisions/0005-adapter-failure-surfacing-contract.md)
- [ADR 0007](../Decisions/0007-adapt-incomes-june-boundaries.md)

## Responsibility Boundaries

| Layer | Owns | Must not own |
| --- | --- | --- |
| Domain (`CookleLibrary`) | SwiftData schema, predicates, route helpers, validation, canonical mutations, canonical search, mutation effect hints | Widget reloads, notification registration, review prompts, deep-link delivery, App Intent result shaping, SwiftUI presentation state |
| Adapter (`Cookle`, `Widgets`, `Watch`, App Intents) | Parameter parsing, platform API calls, dependency wiring, route intake, follow-up orchestration after shared mutations, App Intent result mapping | Re-implementing recipe, diary, tag, or reset mutation rules |
| View (SwiftUI) | Focus state, sheets, dialogs, navigation state, screen-scoped `@Observable` models, display formatting, view composition | Canonical business validation, mutation rules, notification scheduling, widget reload coordination |

## Testing Boundary

- Keep repository-owned unit tests in `CookleLibrary/Tests`.
- Do not maintain a separate unit test target for `Cookle`, `Widgets`, or `Watch`.
- App-owned adapters should stay responsibility-thin enough to verify through
  `Cookle` builds plus `CookleLibrary` test coverage.
- If an adapter or screen model needs durable coverage, first move the reusable
  rule into `CookleLibrary` and test it there instead of growing target-local
  test suites.

## View Rules

Allowed in views:

- focus and keyboard behavior
- sheet, alert, and navigation presentation
- small screen-scoped `@Observable` models owned by the root view
- display-only formatting

Not allowed in views:

- re-implementing recipe, diary, tag, or reset mutation rules
- direct notification synchronization or widget reload orchestration
- App Intent-only success semantics
- review prompting decisions that belong in adapters

## Screen-Scoped Presentation Models

When a screen grows beyond trivial local state, keep a screen-scoped
`@Observable` model in the root view's `@State` and pass it with `@Bindable`.

Current examples:

- `Cookle/Sources/Main/State/MainNavigationRouter.swift`
- `Cookle/Sources/Recipe/Models/RecipeFormModel.swift`
- `Cookle/Sources/Recipe/Services/RecipeFormSaveCoordinator.swift`
- `Cookle/Sources/Diary/Models/DiaryFormModel.swift`
- `Cookle/Sources/Diary/Services/DiaryFormSaveCoordinator.swift`
- `Cookle/Sources/Settings/Models/SettingsScreenModel.swift`

Prefer this over `ObservableObject`, `EnvironmentObject`, or pushing
screen-local sequencing into a broader router.

## Canonical Mutation Flow

`View or App Intent -> app adapter/service -> CookleLibrary service -> MutationOutcome<Value> -> app-side follow-up`

The current app-side mutation adapters are:

- `Cookle/Sources/Recipe/Services/RecipeActionService.swift`
- `Cookle/Sources/Diary/Services/DiaryActionService.swift`
- `Cookle/Sources/Photo/Services/PhotoActionService.swift`
- `Cookle/Sources/Tag/Services/TagActionService.swift`
- `Cookle/Sources/Settings/Services/SettingsActionService.swift`

Those adapters may coordinate widget reloads, notification refreshes, and
review prompting after a shared mutation succeeds, but the mutation rules and
effect hints belong in `CookleLibrary`.

## App Intent Mapping

App Intents are adapters, not a second domain layer.

Preferred flow:

`App Intent parameter parsing -> same app adapter/service -> same CookleLibrary API`

App Intent files may:

- resolve entities and parameters
- convert domain and adapter failures into intent-facing errors
- return dialogs, values, and route-based navigation

App Intent files must not:

- become the only implementation of a user-facing mutation
- return success results after blocking preflight or primary mutation failures
- duplicate shared validation, search, or mutation branching

## MutationOutcome Contract

Shared mutations express follow-up hints through:

- `CookleLibrary/Sources/Common/MutationOutcome.swift`
- `CookleLibrary/Sources/Common/MutationEffect.swift`

Current effect hints are:

- `recipeDataChanged`
- `diaryDataChanged`
- `notificationPlanChanged`
- `reviewPromptEligible`

`reviewPromptEligible` stays app-owned. `CookleLibrary` returns domain-owned
effects, and app adapters may append review eligibility when the initiating
surface should attempt it.

## Failure-Surfacing Contract

Adapter-owned mutation and destructive-reset paths must classify failures by
phase instead of relying on assertions or success sentinel values.

- preflight and primary mutation failures block success and must stay visible
  to the current caller
- UI flows must keep the current form or destructive confirmation context on
  blocking failures
- App Intents must throw on blocking failures instead of returning success
  dialogs
- post-commit follow-up failures are degraded-success cases and must not claim
  that the committed mutation was rolled back

See
[ADR 0005](../Decisions/0005-adapter-failure-surfacing-contract.md)
for the repository-level contract.

## SwiftData Boundary

Keep in `CookleLibrary`:

- `@Model` types
- predicates and `FetchDescriptor` builders
- domain mutation and validation services
- route parsing and execution helpers that are reusable across surfaces

Keep in target adapters:

- `ModelContainer` construction
- iCloud enablement policy
- `MHAppRuntimeBootstrap` and `MHAppRoutePipeline` assembly
- `UNUserNotificationCenter` integration
- WidgetKit reload coordination
- WatchConnectivity snapshot delivery and watch companion interaction state
- review prompt orchestration

API style decision:

- Keep accepting `ModelContext` in library APIs.
- Rationale: Cookle is already `SwiftData` and `@Query` centered, and the
  current migration goal is clearer boundaries rather than a persistence actor
  rewrite.

## Current Hotspots and Minimal Refactor Plans

1. Route assembly should stay separate from navigation state mutation.
   Files:
   - `Cookle/Sources/Main/Services/MainRouteService.swift`
   - `Cookle/Sources/Main/State/MainNavigationRouter.swift`
   Minimal plan:
   - keep `MainRouteService` focused on pipeline assembly, parsing, and inbox
     sources
   - keep `MainNavigationRouter` focused on navigation state application

2. Form screens should keep state in screen models instead of large view-local
   mutation code.
   Files:
   - `Cookle/Sources/Recipe/Views/RecipeFormView.swift`
   - `Cookle/Sources/Diary/Views/DiaryFormView.swift`
   - `Cookle/Sources/Settings/Views/SettingsSidebarView.swift`
   Minimal plan:
   - keep views focused on UI composition and error presentation
   - keep form state, tip priority, and save sequencing in dedicated models and
     coordinators

3. Mutation follow-up hints must stay shared while platform side effects stay
   app-owned.
   Files:
   - `CookleLibrary/Sources/Recipe/RecipeFormService.swift`
   - `CookleLibrary/Sources/Diary/DiaryService.swift`
   - `CookleLibrary/Sources/Tag/TagService.swift`
   - `CookleLibrary/Sources/Common/DataResetService.swift`
   Minimal plan:
   - keep effect-hint decisions in `CookleLibrary`
   - keep notification sync, widget reload, and review flow wiring in app-side
     adapters

4. Notification route delivery should stay adapter-owned without duplicating
   route meaning.
   Files:
   - `Cookle/Sources/Notification/Services/NotificationService.swift`
   - `CookleLibrary/Sources/Route/*`
   Minimal plan:
   - keep payload decoding and delivery in notification adapters
   - keep route vocabulary and parsing shared in `CookleLibrary`
