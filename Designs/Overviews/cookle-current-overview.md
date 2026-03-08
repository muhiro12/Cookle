# Cookle Product and Architecture Overview

Implementation snapshot based on the repository state on March 8, 2026.

## Purpose

This document summarizes Cookle's current user-facing functionality, internal
product scope, and architecture policy in one place.

Cookle is an iOS recipe manager built with SwiftUI and SwiftData. The product
focus is personal cooking organization:

- Save and maintain a private recipe database.
- Plan or log meals by day.
- Reuse recipe metadata across search, widgets, notifications, and Shortcuts.
- Keep shared business logic reusable across the app, widgets, and App Intents.

## Product Snapshot

- Minimum deployment target: iOS 18.0
- Core stack: SwiftUI, SwiftData, App Intents
- Shared package: `CookleLibrary`
- Main app target: `Cookle`
- Widget extension target: `Widgets`
- Optional premium capabilities: iCloud sync and ad removal
- Remote configuration can require an app update before the main UI continues

## Main Navigation Model

Cookle uses adaptive tab navigation.

- Core tabs are `Diary`, `Recipe`, `Photo`, and `Search`.
- On regular-width layouts, `Ingredient`, `Category`, and `Settings` are shown
  as dedicated destinations.
- On compact layouts, secondary destinations are grouped behind `Menu`.
- `Debug` is available only when debug mode is enabled and the layout is
  regular width.
- Deep links, widgets, notifications, and App Intents all feed the same route
  system through an ordered source chain, so navigation behavior is shared
  across entry points.

## Functional Scope

### Recipe Management

- Create recipes with:
  - name
  - ordered photos
  - serving size
  - cooking time
  - ordered ingredients with amounts
  - ordered steps
  - categories
  - free-form note
- Edit existing recipes with the same form model.
- Duplicate an existing recipe into a new draft.
- Delete recipes from the detail screen, list context menus, or App Intents.
- Show recipe detail with:
  - photo gallery
  - serving size
  - cooking time
  - ingredients
  - steps
  - categories
  - note
  - related diaries
  - created and updated timestamps
- Keep the screen awake while a recipe detail view is open.
- Track the last opened recipe for widgets and Shortcuts.
- Offer inline ingredient and category suggestions while editing based on
  existing tags.
- Support bulk multiline entry for ingredients and steps.
- Validate recipe drafts before mutation:
  - recipe name is required
  - serving size and cooking time must parse as integers
  - full-width digits are normalized before numeric parsing
- Reuse existing `Ingredient`, `Category`, and identical `Photo` records instead
  of blindly duplicating them when possible.

### Recipe Text Inference

- On iOS 26.0 and later, the recipe form can infer structured recipe data from
  free-form text.
- The inference flow can import text from:
  - manual text entry
  - photo library OCR
  - camera OCR
- OCR is powered by Vision text recognition.
- Structured inference is powered by Foundation Models when available.
- If model-based inference fails, Cookle falls back to heuristics that extract:
  - recipe name from the first non-empty line
  - serving size from simple `serves N` or `for N` patterns
  - cooking time from simple `N minutes` patterns

### Recipe Images

- Recipes can import photos from the system photo picker.
- On iOS 18.1 and later, recipes can generate images with Image Playground.
- If a recipe is created without a photo and Image Playground is supported,
  Cookle immediately offers to generate one.
- Generated images are stored as recipe photos and marked with the
  `imagePlayground` source.
- Imported photos are marked with the `photosPicker` source.

### Diary Management

- Create a diary for a specific date.
- Assign saved recipes to breakfast, lunch, and dinner sections.
- Add a free-form daily note.
- Update or delete an existing diary.
- Add a recipe directly to today's diary from an App Intent.
- Show diary detail with:
  - breakfast recipes
  - lunch recipes
  - dinner recipes
  - note
  - created timestamp
  - updated timestamp
- Group diary lists by year and month.
- Show diary labels with the date plus recipe photo thumbnails.

### Search

- The dedicated search screen uses the canonical shared recipe search service.
- Search matches recipe names, ingredient tags, and category tags.
- Short queries under three characters use exact equality for tag matching.
- Longer queries use partial matching for names, ingredients, and categories.
- Name and tag matching normalize Hiragana and Katakana variants.
- The recipe list also has a lighter local filter for quick name narrowing.

### Photo Library

- Show a gallery of photos linked to recipes.
- Separate gallery sections by photo source:
  - Photos
  - Image Playground
- Open a photo detail screen from the gallery or from a recipe.
- Show all recipes linked to a photo.
- Present photos in a full-screen swipeable viewer.

### Tag Management

- Maintain two tag domains:
  - ingredients
  - categories
- Browse tags and see which recipes use each tag.
- Search tags by text.
- Rename tags from the tag detail flow or App Intents.
- Delete categories freely.
- Prevent deletion of ingredients that are still used by recipes.
- Rebuild scheduled recipe suggestion notifications after tag mutations so
  notification content stays aligned with ingredient metadata.

### Settings and Product Controls

- Subscription screen powered by StoreKit wrapper components.
- iCloud toggle shown only for subscribed users.
- Daily recipe suggestion notification controls:
  - enable or disable notifications
  - choose notification time
  - send a test notification
  - open system notification settings when permission is denied
- Delete all persisted app data with destructive confirmation.
- Show third-party license information.
- Re-show TipKit onboarding tips on demand.
- Show the system Shortcuts link entry point.

### Notifications

- Schedule one daily recipe suggestion notification when the setting is enabled.
- Plan notifications up to 14 days ahead.
- Use deterministic recipe rotation so suggestions remain stable across
  refreshes.
- Avoid repeating the same recipe on consecutive days when multiple candidates
  exist.
- Attach a compressed preview image when the recipe has a photo.
- Deep link notification taps into the recipe detail screen when possible.
- Provide a foreground notification action to browse recipes.
- Keep notification schedules in sync after recipe mutations, tag mutations,
  settings changes, and launch/foreground refreshes.

### Widgets

- `Diary` widget supports:
  - today
  - latest
  - random
- `Recipe` widget supports:
  - last opened
  - latest
  - random
- Widgets deep link back into the same shared route system as the app.
- The diary widget refreshes at the next day boundary for the `today` mode and
  roughly every six hours for other modes.
- The recipe widget refreshes roughly every six hours.
- Recipe widget images are downsampled for widget family size before display.

### App Shortcuts and App Intents

- Shortcut tiles currently exposed in `CookleShortcuts`:
  - open Cookle
  - open recipes
  - show search result
  - show last opened recipe
  - show random recipe
  - show today's diary
  - open settings
- Additional App Intents support:
  - open a specific recipe
  - create, update, and delete recipes
  - search recipes and return entities
  - infer a recipe from text on iOS 26.0+
  - create, update, show, and delete diaries
  - add a recipe to today's diary
  - rename and delete ingredient and category tags
  - open settings, subscription, or license destinations
- App Intents use the same shared model container and workflow services as the
  app instead of owning separate business logic.

### Deep Links and External Entry Points

- Custom URL scheme: `cookle://...`
- Universal link host: `https://muhiro12.github.io/Cookle/...`
- Supported routes:
  - `home`
  - `diary`
  - `diary/YYYY-MM-DD`
  - `recipe`
  - `recipe?id=<base64PersistentIdentifier>`
  - `search`
  - `search?q=<query>`
  - `settings`
  - `settings/subscription`
  - `settings/license`
- The same route parser and executor are used by:
  - app `onOpenURL` and universal links, which first ingest into the shared
    route inbox
  - widgets
  - notification taps
  - App Intent route handoff

### Monetization, Sync, and Configuration

- Subscription state is resolved from StoreKit product membership at launch.
- When the subscription is inactive, Cookle automatically turns off the local
  iCloud sync preference.
- Native ads are shown in diary and recipe flows for non-subscribers.
- Premium users do not see those ad sections.
- The app fetches remote configuration from GitHub and can force users to
  update before continuing.
- A shared runtime lifecycle plan refreshes subscription state, remote
  configuration, notification schedules, and pending routes during initial load
  and foreground transitions.

### Debug and Preview Support

- Debug mode can be enabled through AppStorage.
- The debug screen provides:
  - a debug mode toggle
  - TipKit reset and testing helpers
  - preview screens for subscriptions, ads, and shortcuts link
  - raw model browsing for diaries, recipes, photos, ingredients, categories,
    and sub-objects
  - direct deletion of model records from the debug content browser
- Preview helpers seed an in-memory SwiftData store and reuse the same app
  context wiring pattern as the live app before injecting environment services.

## Data Model

The persistent schema currently includes:

- `Recipe`
- `Diary`
- `Photo`
- `Category`
- `Ingredient`
- `DiaryObject`
- `PhotoObject`
- `IngredientObject`

Important modeling choices:

- `Recipe` owns ordered `PhotoObject` and `IngredientObject` collections.
- `Diary` owns ordered `DiaryObject` entries for breakfast, lunch, and dinner.
- `Photo`, `Category`, and `Ingredient` are shared records reused by multiple
  recipes.
- Timestamps are stored on all primary and sub-object records.
- The migration plan is versioned as schema `1.0.0`.

## Architecture Policy

Cookle intentionally follows Apple's app architecture closely instead of adding
large custom abstraction layers.

### Layering

- `CookleLibrary` is the shared core.
- `Cookle` is the main app adapter layer.
- `Widgets` is a target-local adapter layer for WidgetKit.

### What belongs in `CookleLibrary`

- SwiftData models
- predicates and fetch descriptors
- validation and mutation services
- schema migration and storage helpers
- shared route parsing and route execution
- reusable logic that should behave the same in the app, widgets, and intents

### What belongs in `Cookle`

- SwiftUI screens
- App Intents
- app bootstrap context and runtime lifecycle plans
- workflow orchestration services
- notifications
- review prompting
- widget reload coordination
- app-only route inbox handling
- local presentation state

### Workflow Service Rule

User-facing mutations should go through workflow services in the app target.

Current workflow services are:

- `RecipeActionService`
- `DiaryActionService`
- `TagActionService`
- `SettingsActionService`

Their role is to call shared domain services first, then run app-only side
effects such as widget reloads, notification sync, or review prompts.

Current workflow-specific follow-up policies include:

- `RecipeActionService` owns review prompting and recipe/widget/notification
  follow-up after successful recipe mutations.
- `DiaryActionService` owns diary widget follow-up after successful diary
  mutations.
- `TagActionService` owns notification refresh after successful tag mutations.
- `SettingsActionService` owns notification-setting normalization/application
  and destructive reset orchestration.

### App Intent Rule

App Intents are treated as adapters, not domain owners.

- They resolve parameters and entities.
- They call shared services or app workflow services.
- They return dialogs, values, snippet views, or route actions.
- They do not duplicate canonical mutation or validation logic.

### View Ownership Rule

Views may own:

- local form state
- focus state
- sheet presentation
- selection state
- lightweight display formatting

Views should not own:

- canonical business rules
- duplicate validation logic
- cross-target side effects
- independent search implementations

### Canonical Behavior Rules

- `RecipeService.search` is the canonical recipe search implementation.
- Route parsing and route execution are shared so every entry point uses the
  same navigation vocabulary.
- Target-specific side effects stay out of `CookleLibrary`.
- Repository-heavy or protocol-heavy persistence abstractions are intentionally
  avoided unless a concrete need appears.

### Storage and Migration Policy

- The main app builds its model container through `ModelContainerFactory`.
- Legacy store files are migrated before the current container is used.
- Migrated data is validated before legacy files are deleted.
- Validation currently requires recipe and diary object counts to match between
  legacy and current stores.
- Shared preferences use an app-group-backed store when cross-target access is
  needed.

## Operational Notes

- Standard build and test entry point: `bash ci_scripts/tasks/verify.sh`
- Shared package tests cover core reusable behavior such as:
  - search
  - route parsing and URL building
  - preferences
  - migrations
  - diary, recipe, and tag services
  - notification scheduling helpers

## Summary

Cookle is currently a recipe-first cooking companion with four strong pillars:
recipe management, diary logging, shared search/navigation infrastructure, and
system integrations such as widgets, notifications, and Shortcuts.

The central design policy is stable and explicit: shared business logic lives in
`CookleLibrary`, while the app target owns orchestration and side effects.
