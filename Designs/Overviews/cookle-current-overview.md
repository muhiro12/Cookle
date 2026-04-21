# Cookle Product and Architecture Overview

Implementation snapshot based on the repository state on April 12, 2026.

## Purpose

This document summarizes Cookle's current user-facing functionality, internal
product scope, and architecture policy in one place.

Related audits:

- [Cookle Architecture Conformance Audit](cookle-architecture-conformance-audit.md)
- [Cookle Data Deletion Policy Audit](cookle-data-deletion-policy-audit.md)

The deletion-policy audit is also the source of truth for forward delete,
unlink, and orphan-handling decisions.

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

- Core tabs are `Diary`, `Recipe`, `Photo`, `Settings`, and `Search`.
- Ingredient and category tag browsing is opened from the search discovery
  sheet, which leads into the dedicated tag detail flow on both compact and
  regular-width layouts.
- `Debug` is available from `Settings` when debug mode is enabled.
- Deep links, widgets, notifications, and App Intents all feed the same route
  system through `MHAppRoutePipeline`, so navigation behavior is shared across
  entry points.

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
- The recipe list uses the same canonical shared browse/search semantics with
  shared sort modes.
- Search matches recipe names, ingredient tags, and category tags.
- Short queries under three characters use exact equality for tag matching.
- Longer queries use partial matching for names, ingredients, and categories.
- Name and tag matching normalize Hiragana and Katakana variants.

### Photo Library

- Show a gallery of all stored photos, including photos that are no longer
  linked to recipes.
- Treat photo unlink and explicit asset delete as separate concepts in the
  deletion policy, even though ordinary asset delete is not yet exposed in the
  main UI.
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
- Browse tags from the search discovery sheet and see which recipes use each
  tag.
- Search tags by text.
- Keep unused tags visible so conservative retention does not make them
  unreachable from the product UI.
- Rename tags from the tag detail flow or App Intents.
- Allow category delete from category-focused surfaces with recipe-impact
  confirmation.
- Allow ingredient delete only when the ingredient is unused, and explain the
  in-use rejection in both UI and App Intents.
- Rebuild scheduled recipe suggestion notifications after tag mutations so
  notification content stays aligned with ingredient metadata.

### Settings and Product Controls

- Subscription and license screens are presented through MHPlatform runtime
  surfaces.
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
  - rename ingredient and category tags
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
  - `MHAppRoutePipeline`, which wires app `onOpenURL`, universal links,
    pending notification routes, and App Intent route handoff into one route
    drain path
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
- When debug mode is enabled, the debug screen is opened from `Settings`.
- The debug screen provides:
  - a debug mode toggle
  - TipKit reset and testing helpers
  - preview screens for subscriptions, ads, and shortcuts link
  - raw model browsing for diaries, recipes, photos, ingredients, categories,
    and sub-objects
  - direct deletion of model records from the debug content browser
- Preview helpers seed an in-memory SwiftData store and reuse the same
  `CookleAppAssembly` factory path used by the live app, injecting shared
  dependencies and runtime state without running the full lifecycle bootstrap.

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
- `DiaryObject`, `PhotoObject`, and `IngredientObject` are treated as
  parent-owned disposable rows, while root and shared records default to
  conservative retention unless a delete surface explicitly says otherwise.
- Timestamps are stored on all primary and sub-object records.
- The migration plan is versioned as schema `1.0.0`.

## Persistence

Cookle currently splits persistence into two roles.

### Authoritative Application Data

`SwiftData` is the source of truth for user-owned cooking data.

- `Recipe`
- `Diary`
- `Photo`
- `Category`
- `Ingredient`
- `DiaryObject`
- `PhotoObject`
- `IngredientObject`

Those records are the authoritative application state. They are expected to
survive app restarts, updates, and preference cleanup. Recipe content, diary
content, photos, tags, and ordered sub-objects belong here rather than in
`AppStorage` or raw `UserDefaults`.

### Preference-Style State

`AppStorage` is the preferred SwiftUI surface for lightweight preference-style
state. Outside SwiftUI, the app reaches the same storage through
descriptor-backed `MHPreferenceStore`, `CooklePreferences`, and
`CookleSharedPreferences`.

The app currently uses two app-owned `UserDefaults` domains:

- the standard app domain for app-local preference-style state
- the app-group suite for cross-target state shared with widgets and App
  Intents

At startup, `CookleAppBootstrapModel` runs `CooklePreferenceLifecycle` before
model-container preparation. That lifecycle enumerates the current app-owned
descriptors from the `CookleLibrary` `MHPreferenceDescriptors` extension plus
app-owned snapshot, logging, and lifecycle-state descriptors gathered in
`CookleKnownStorageDescriptors`. The storage-key strings themselves are
centralized in `CookleUserDefaultsKeys`, and the lifecycle uses the resulting
descriptor catalog to remove unknown keys from the standard app domain and the
shared suite. In other words, the app-owned preference surface is intentionally
closed: only declared descriptors survive cleanup.

| Key group | Backing domain | Purpose | Safe to lose? | Cleanup target? |
| --- | --- | --- | --- | --- |
| `MHPreferenceDescriptors` bool descriptors | `standard` | UI and product-control flags | Yes | Yes |
| `MHPreferenceDescriptors` int descriptors | `standard` | Notification time and tip progress | Yes | Yes |
| `MHPreferenceDescriptors.lastLaunchedAppVersion` | `standard` | App version marker | Yes | Yes |
| `MHPreferenceDescriptors.lastOpenedRecipeID` | shared suite | Cross-target last-opened pointer | Yes | Yes |
| `MHPreferenceDescriptors.pendingIntentDeepLinkURL` | shared suite | Temporary App Intent route handoff | Yes | Yes |
| `loggingCurrentSession`, `loggingPreviousSession` | `standard` | Diagnostic log snapshots | Yes | Yes |
| `diaryFormSnapshot`, `recipeFormSnapshot` | `standard` | Create-flow draft snapshots | Yes | Yes |
| `preferenceLifecycleState` | `standard` | Cleanup bookkeeping state | Yes | Yes |

Recent cleanup intentionally does not rescue several retired keys:

- `pendingCookleIntentDeepLinkURL`, because it was only a temporary route
  handoff queue
- `cookle.logging.last-session.current-session` and
  `cookle.logging.last-session.previous-session`, because they were diagnostic
  snapshots rather than user data
- `cookle.formSnapshot.diary` and `cookle.formSnapshot.recipe`, because they
  were draft-assistance snapshots and the snapshot feature has not shipped yet
- `cookle.preferences.lifecycle-state`, because it was internal bookkeeping
  state
- legacy standard-domain `lastOpenedRecipeID`, because it was only a low-value
  last-opened pointer and the current owner is the shared suite

This cleanup policy applies only to the app-owned standard domain and the
app-group shared suite. It does not clean system-owned domains or the SwiftData
store.

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
- app-owned root assembly, runtime bootstrap, and runtime lifecycle plans
- workflow orchestration services
- notifications
- review prompting
- widget reload coordination
- app-owned route pipeline semantics and navigation application
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

They currently express mutation follow-up through
`MHMutationWorkflow.runThrowing(..., adapterValue:)` and
`MHMutationProjectionStrategy`, and attach recipe review prompting through
`MHReviewFlow`.

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
- `CookleLibrary` also owns the canonical recipe browse sort semantics and
  persisted photo ordering/removal rules.
- Route parsing and route execution are shared so every entry point uses the
  same navigation vocabulary.
- Target-specific side effects stay out of `CookleLibrary`.
- Repository-heavy or protocol-heavy persistence abstractions are intentionally
  avoided unless a concrete need appears.

### Storage and Migration Policy

- The main app builds its model container through `ModelContainerFactory`.
- Legacy store files are relocated through `MHPlatform` persistence maintenance
  before the current container is used.
- The relocated store is validated by opening a `ModelContainer` before legacy
  files are deleted.
- Shared preferences use an app-group-backed store when cross-target access is
  needed.

## Operational Notes

- Standard build and test entry point: `bash ci_scripts/tasks/verify_task_completion.sh`
- Repository-owned unit tests stay concentrated in `CookleLibrary/Tests`.
- `Cookle` and `Widgets` are verified through app builds plus shared-library
  tests, without a separate app unit test target.
- Shared package tests cover core reusable behavior such as:
  - search
  - browse sort modes
  - photo ordering and removal
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
