# Shared Service Design

## Purpose

This document explains where shared logic belongs in Cookle when the same
operation must work across the iOS app, widgets, and App Intents.

## Core Principles

- `CookleLibrary` is the source of truth for shared business logic.
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
| Shared domain logic | `CookleLibrary` | `Recipe`, `Diary`, `Tag`, predicates, `RecipeFormService`, `RecipeService`, `DiaryService`, `TagService`, `DataResetService` |
| Apple framework adapters | `Cookle`, `Widgets`, `Watch` | `NotificationService`, App Intent types, widget timeline/provider types, `WatchCookingSessionStore` |
| App-side platform support | `Cookle/Sources/Common/Platform` | `CookleAppAssemblyFactory`, `MHAppRuntimeBootstrap` assembly, `MHAppRoutePipeline<CookleRoute>` assembly |
| Presentation orchestration | `Cookle`, `Widgets`, `Watch` | SwiftUI views, widget view composition, `MainNavigationRouter`, `RecipeFormModel`, `RecipeFormSaveCoordinator`, `DiaryFormModel`, `DiaryFormSaveCoordinator`, `SettingsScreenModel`, `WatchActiveCookingView` |

## MHPlatform Adoption

- `Cookle` is the intentional `MHPlatform` umbrella adopter.
- `CookleLibrary` adopts `MHPlatformCore` and must not depend on the
  full `MHPlatform` umbrella.
- `Widgets` and `Watch` stay off direct umbrella adoption.
- This repository intentionally uses the MHPlatform 1.x semver range
  `1.0.0..<2.0.0`.

## Canonical Shared APIs

The following types are the current shared entry points for business
operations:

- `RecipeBrowseCriteria`
- `RecipeBrowseSortMode`
- `RecipeFormDraft`
- `MutationOutcome`
- `MutationEffect`
- `RecipePhotoRemovalBehavior`
- `RecipeService.search(context:criteria:)`
- `RecipeFormService.createWithOutcome(context:draft:)`
- `RecipeFormService.updateWithOutcome(context:recipe:draft:)`
- `RecipeService.deleteWithOutcome(context:recipe:)`
- `RecipeService.removePhotoWithOutcome(context:recipe:photoObject:)`
- `RecipeService.recordLastOpenedRecipeWithOutcome(_:)`
- `DiaryService.createWithOutcome(context:date:breakfasts:lunches:dinners:note:)`
- `DiaryService.updateWithOutcome(context:diary:date:breakfasts:lunches:dinners:note:)`
- `DiaryService.addWithOutcome(context:date:recipe:type:)`
- `DiaryService.deleteWithOutcome(context:diary:)`
- `TagService.renameWithOutcome(...)`
- `DataResetService.deleteAllWithOutcome(context:)`

App-side mutation call sites should consume those library APIs and keep
platform-only side effects in the app target.

## Placement Rules

1. If an operation is reusable across more than one surface, add or extend a
   library service first.
2. If an operation depends on Apple-only frameworks, keep it in `Cookle` and
   make it call library APIs.
3. If a view or App Intent starts recreating mutation rules, treat that as a
   missing library API.
4. Keep platform-specific types out of `CookleLibrary`. Convert them at the
   boundary into library models or value types.
5. If glue code is app-only but reused by multiple app entry points, factor it
   into `Cookle/Sources/Common/Platform` or a dedicated app-side service.

## Test Posture

- Keep repository-owned unit tests in `CookleLibrary/Tests`.
- Do not add a separate unit test target for `Cookle` or `Widgets`.
- If an app-side adapter or screen model starts needing durable coverage, first
  extract the reusable rule into `CookleLibrary` and test it there.

## Current Examples

- `MainNavigationRouter` stays in `Cookle` because navigation meaning and
  compact settings presentation are app-only concerns.
- `RecipeFormSaveCoordinator` and `DiaryFormSaveCoordinator` stay in `Cookle`
  because they convert screen state into canonical library drafts and inputs.
- `RecipeFormService`, `DiaryService`, `TagService`, and `DataResetService`
  stay in `CookleLibrary` because their mutation rules must remain stable
  across the app and App Intents.
- `NotificationService` stays in `Cookle` because scheduling, authorization,
  and route delivery depend on Apple frameworks.
- `SettingsActionService` stays in `Cookle` because destructive reset follow-up
  is platform orchestration, while the actual reset decision stays in
  `DataResetService`.

## Refactoring Heuristic

When a business rule is duplicated, the default fix is to move the rule into
`CookleLibrary` rather than duplicating it in a view, App Intent, or widget.

When the duplicated code is still Apple-framework glue, the default fix is to
extract it into an app-side adapter in `Cookle/Sources/Common/Platform` or a
feature-local app service.
