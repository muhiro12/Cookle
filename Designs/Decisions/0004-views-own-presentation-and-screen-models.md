# ADR 0004: Views Own Presentation and Screen Models

- Date: 2026-03-23
- Status: Accepted

## Context

Several Cookle screens had grown state-heavy enough that view files mixed form
state, save sequencing, tip priority, and user-facing error presentation in one
place.

The issue was not that SwiftUI views owned presentation. The issue was that the
presentation state had become too large to keep implicit.

## Decision

Views continue to own presentation, but state-heavy screens should move that
presentation into screen-scoped `@Observable` models and small coordinators.

Preferred shape:

- root view owns a screen model in `@State`
- child views consume the model with `@Bindable`
- save or destructive sequencing lives in a small coordinator when the screen
  needs it

Current examples:

- `RecipeFormModel`
- `RecipeFormSaveCoordinator`
- `DiaryFormModel`
- `DiaryFormSaveCoordinator`
- `SettingsScreenModel`
- `MainNavigationRouter`

## Consequences

- Views stay focused on composition and error presentation.
- Screen-local behavior remains explicit without introducing broader global
  state.
- Business rules still move to `CookleLibrary` when they must be reused across
  surfaces.
