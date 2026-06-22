# Shared Service Design

## Purpose

This document explains where shared logic belongs in Cookle when the same
operation must work across the iOS app, widgets, and App Intents.

## Core Principles

- `CookleLibrary` is the source of truth for shared business logic.
- Public cross-surface business use cases enter through explicit `*Operations`
  facades. Lower-level services, calculators, builders, planners, loaders,
  parsers, and codecs stay as narrower collaborators unless they are durable
  contracts in their own right.
- Target-local adapters own Apple-framework integrations and presentation
  orchestration.
- App Intents are adapters, not a second domain layer.
- Views own presentation state and screen-scoped models, but not canonical
  business rules.
- `CookleLibrary` remains a single module unless there is a stronger reason
  than code organization alone.

## Responsibility Boundaries

| Concern | Lives in | Examples |
| --- | --- | --- |
| Shared domain logic | `CookleLibrary` | `Recipe`, `Diary`, `Tag`, predicates, `RecipeOperations`, `RecipeFormOperations`, `DiaryOperations`, `TagOperations`, `DataMaintenanceOperations` |
| Apple framework adapters | `Cookle`, `Widgets`, `Watch` | `NotificationService`, App Intent types, widget timeline/provider types, `WatchCookingSessionStore` |
| App-side platform support | `Cookle/Sources/Platform` | `CookleAppAssemblyFactory`, `MHAppRuntimeBootstrap` assembly, `MHAppRoutePipeline<CookleRoute>` assembly |
| Presentation orchestration | `Cookle`, `Widgets`, `Watch` | SwiftUI views, widget view composition, `MainNavigationRouter`, `RecipeFormModel`, `RecipeFormSaveCoordinator`, `DiaryFormModel`, `DiaryFormSaveCoordinator`, `SettingsScreenModel`, `WatchActiveCookingView` |

## Source Layout

- `Cookle/Sources/App` is for app entry points, app-level App Intents,
  app-wide support, and generic workflow adapters.
- `Cookle/Sources/Features` is for feature-owned SwiftUI, App Intents,
  presentation models, and target-local action services.
- `Cookle/Sources/Platform` is for app-side Apple framework and package glue
  that is reused by multiple app entry points.
- `Cookle/Sources/SharedUI` is for reusable app-target UI components,
  modifiers, styles, navigation environment helpers, and tips.
- `CookleLibrary/Sources/<Capability>` is for shared capability groups rather
  than a broad `Common` folder.
- `Widgets/Sources/App` and `Watch/Sources/App` contain target entry wiring;
  their `Features` folders contain visible surface behavior.
- `CookleLibrary/Tests/Default/<Capability>` mirrors the shared-library
  source capabilities.

## Operations Migration

Cookle follows the Incomes June boundary direction without copying
finance-domain behavior. Public `*Operations` facades are the shared-library
application layer for delivery surfaces.

Use this rule for new work:

1. Add or extend `*Operations` when a delivery surface needs a public business
   use case.
2. Keep services, calculators, builders, planners, loaders, parsers, and codecs
   as narrower collaborators when they are implementation details.
3. Keep existing services internal when they only support Operations or tested
   library behavior.

Delivery surfaces should not call calculators, builders, planners, loaders,
or parser helpers for business behavior when an Operations boundary can own
that use case.

## Package Consumer Boundaries

- `Cookle` is the intentional `MHPlatform` umbrella adopter.
- `CookleLibrary` adopts `MHPlatformCore` and must not depend on the
  full `MHPlatform` umbrella.
- `Widgets` and `Watch` call `CookleLibrary` first and stay off direct
  app-runtime umbrella adoption.
- This repository intentionally uses the MHPlatform 1.x semver range
  `1.0.0..<2.0.0` with a checked-in `1.9+` resolved baseline.
- `Cookle` adopts `MHDesign` from MHUI as a metrics-only presentation
  dependency for shared spacing and radius values.
- `CookleLibrary` stays presentation-free and must not depend on MHUI or
  MHDesign.
- `Widgets` and `Watch` stay off MHUI and MHDesign by default; they should call
  shared Operations APIs first and add direct presentation package dependencies
  only for an explicit surface-level reason.
- Cookle does not keep a generic utility package dependency. Generic utilities
  should not be treated as an MHUI migration target unless a utility becomes a
  stable platform-foundation contract.

## Canonical Shared APIs

The following types are the current shared entry points for business use cases
and supporting contracts:

- `RecipeBrowseCriteria`
- `RecipeBrowseSortMode`
- `RecipeFormDraft`
- `MutationOutcome`
- `MutationEffect`
- `RecipePhotoRemovalBehavior`
- `RecipeOperations`
- `RecipeFormOperations`
- `RecipeInferenceOperations`
- `DiaryOperations`
- `TagOperations`
- `PhotoOperations`
- `DataMaintenanceOperations`

Delivery-surface call sites should consume Operations APIs and keep
platform-only side effects in the app target. Existing `*Service` types remain
as implementation collaborators rather than public delivery-surface APIs.

## Placement Rules

1. If an operation is reusable across more than one surface, add or extend a
   library `*Operations` facade first.
2. If an operation depends on Apple-only frameworks, keep it in `Cookle` and
   make it call library Operations or supporting contracts.
3. If a view or App Intent starts recreating mutation rules, treat that as a
   missing Operations boundary.
4. Keep platform-specific types out of `CookleLibrary`. Convert them at the
   boundary into library models or value types.
5. If glue code is app-only but reused by multiple app entry points, factor it
   into `Cookle/Sources/Platform` or a dedicated app-side service.

## Test Posture

- Keep repository-owned unit tests in `CookleLibrary/Tests/Default`.
- Do not add a separate unit test target for `Cookle`, `Widgets`, or `Watch`.
- If an app-side adapter or screen model starts needing durable coverage, first
  extract the reusable rule into `CookleLibrary` and test it there.

## Current Examples

- `MainNavigationRouter` stays in `Cookle` because navigation meaning and
  compact settings presentation are app-only concerns.
- `RecipeFormSaveCoordinator` and `DiaryFormSaveCoordinator` stay in `Cookle`
  because they convert screen state into canonical library drafts and inputs.
- `RecipeOperations`, `RecipeFormOperations`, `DiaryOperations`,
  `TagOperations`, `PhotoOperations`, and `DataMaintenanceOperations` stay in
  `CookleLibrary` because their use cases must remain stable across the app,
  widgets, watch surface, and App Intents.
- Service, builder, and planner types remain in `CookleLibrary` as internal
  implementation collaborators behind the Operations boundary.
- `NotificationService` stays in `Cookle` because scheduling, authorization,
  and route delivery depend on Apple frameworks.
- `SettingsActionService` stays in `Cookle` because destructive reset follow-up
  is platform orchestration, while the actual reset use case is exposed through
  `DataMaintenanceOperations`.

## Refactoring Heuristic

When a business rule is duplicated, the default fix is to move the rule into
`CookleLibrary` behind an Operations facade rather than duplicating it in a
view, App Intent, or widget.

When the duplicated code is still Apple-framework glue, the default fix is to
extract it into an app-side adapter in `Cookle/Sources/Platform` or a
feature-local app service.
