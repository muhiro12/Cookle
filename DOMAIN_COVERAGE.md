# Domain Coverage Map

## Scope

This map defines canonical domain ownership for Cookle and highlights gaps where
canonical rules should be moved into `CookleLibrary` while preserving the
Workflow Service Rule in `Cookle`.

## Coverage Matrix

| Feature area | Canonical in CookleLibrary | Adapter-only in Cookle/Widgets | Observed gaps |
| --- | --- | --- | --- |
| recipes | `Recipe`, `RecipeService`, `RecipeFormService`, `RecipePredicate`, `RecipeBlurbService`, `DailyRecipeSuggestionService` | `RecipeActionService`, recipe SwiftUI views, recipe App Intents | Intent text parsing lived in app code; stable recipe ID conversion duplicated across targets |
| diaries | `Diary`, `DiaryService`, `DiaryObjectType`, `DiaryPredicate` | `DiaryActionService`, diary SwiftUI views, diary App Intents, diary widget timeline rendering | Update/delete target resolution for date-based diary flows lived in Intent branches |
| photos | `Photo`, `PhotoObject`, `PhotoSource`, photo predicates | photo screens, widget image rendering, notification attachment I/O | primary photo selection heuristic duplicated across adapters (not fully unified yet) |
| search | `RecipeService.search` + `RecipePredicate.anyTextMatches` | search UI state, searchable presentation, search intents/snippets | no high-impact gap after canonical search consolidation |
| tags | `TagService`, `TagPredicate`, `TagServiceError` | `TagActionService`, tag forms, tag intents | named lookup helper remains in Intent support (`TagIntentSupport`) |
| routes | `CookleRoute`, parser/executor/url builders/deep-link helpers | `MainRouteService` state mapping, route inbox, openApp intents | no canonical parsing/execution gap observed |
| notifications | suggestion planning (`DailyRecipeSuggestionService`), route URL builders, recipe blurb generation | `UNUserNotificationCenter` orchestration, authorization flow, attachment persistence | time normalization rules duplicated in app (`NotificationService` and `SettingsSidebarView`) |
| widgets | shared model/query/mutation and deep-link vocabulary | WidgetKit providers, timeline policy, widget rendering views | stable recipe identifier conversion duplicated in recipe widget provider |
| intents | shared domain logic consumed via services and workflows | parameter resolution, dialogs, snippet views, open-app behavior | some mutation-target branching and parsing logic leaked into intents |
| migrations | `CookleMigrationPlan`, `DatabaseMigrator`, `ModelContainerFactory`, migration validation | app startup orchestration and fatal-error handling | no high-impact canonical gap observed |

## Evidence Paths

- Recipes:
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Recipe/RecipeService.swift`
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Recipe/RecipeFormService.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Recipe/Services/RecipeActionService.swift`
- Diaries:
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Diary/DiaryService.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Diary/Services/DiaryActionService.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Diary/Intents/UpdateDiaryIntent.swift`
- Photos:
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Photo/Photo.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Notification/Services/NotificationAttachmentStore.swift`
  - `/Users/Hiromu/Repositories/Cookle/Widgets/Sources/Recipe/Providers/RecipeProvider.swift`
- Search:
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Recipe/RecipePredicate.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Search/Views/SearchView.swift`
- Tags:
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Tag/TagService.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Tag/Intents/TagIntentSupport.swift`
- Routes:
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Common/CookleRouteParser.swift`
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Common/CookleRouteExecutor.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Main/Services/MainRouteService.swift`
- Notifications:
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Recipe/DailyRecipeSuggestionService.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Notification/Services/NotificationService.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Settings/Views/SettingsSidebarView.swift`
- Widgets:
  - `/Users/Hiromu/Repositories/Cookle/Widgets/Sources/Recipe/Providers/RecipeProvider.swift`
  - `/Users/Hiromu/Repositories/Cookle/Widgets/Sources/Diary/Providers/DiaryProvider.swift`
- Intents:
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Recipe/Intents/CreateRecipeIntent.swift`
  - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Diary/Intents/DeleteDiaryIntent.swift`
- Migrations:
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Common/DatabaseMigrator.swift`
  - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Common/ModelContainerFactory.swift`

## Top Gaps (Ranked)

Only canonical rules are moved. Platform side effects remain in app workflow
services.

1. Recipe Intent text parsing in app
   - Before:
     - `RecipeIntentDraftBuilder` owned line splitting and `ingredient:amount`
       parsing.
   - After:
     - Canonical parsing moved into `RecipeFormService` text-input API.
     - Intents forward boundary input only.
   - Files:
     - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Recipe/RecipeFormService.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Recipe/Intents/CreateRecipeIntent.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Recipe/Intents/UpdateRecipeIntent.swift`

2. Stable recipe identifier codec duplicated across targets
   - Before:
     - Base64 encode/decode logic lived in app models, intents, widgets, and
       notification workflows.
   - After:
     - Shared codec added in `CookleLibrary` and reused by all adapters.
   - Files:
     - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Common/RecipeStableIdentifierCodec.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Recipe/Models/RecipeEntity.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Recipe/Models/RecipeEntityQuery.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Notification/Services/NotificationService.swift`
     - `/Users/Hiromu/Repositories/Cookle/Widgets/Sources/Recipe/Providers/RecipeProvider.swift`

3. Suggestion-time policy duplicated in app
   - Before:
     - Hour/minute defaults and clamping existed in both notification and
       settings adapters.
   - After:
     - Shared `DailySuggestionTimePolicy` defines canonical normalization and
       conversion.
   - Files:
     - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Common/DailySuggestionTimePolicy.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Notification/Services/NotificationService.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Settings/Views/SettingsSidebarView.swift`

4. Last-opened recipe recording mixed in view code
   - Before:
     - `RecipeView` directly updated shared preferences and reloaded widgets.
   - After:
     - Canonical record persistence moved to `RecipeService`.
     - Workflow service owns side effects.
   - Files:
     - `/Users/Hiromu/Repositories/Cookle/CookleLibrary/Sources/Recipe/RecipeService.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Recipe/Services/RecipeActionService.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Recipe/Views/RecipeView.swift`

5. Diary Intents owned mutation-target branching
   - Before:
     - `UpdateDiaryIntent` and `DeleteDiaryIntent` resolved diaries by date and
       branched on existence.
   - After:
     - Workflow API (`DiaryActionService`) resolves target and returns outcome.
     - Intents stay at boundary responsibility.
   - Files:
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Diary/Services/DiaryActionService.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Diary/Intents/UpdateDiaryIntent.swift`
     - `/Users/Hiromu/Repositories/Cookle/Cookle/Sources/Diary/Intents/DeleteDiaryIntent.swift`

## Workflow Mutation Contract

`CookleLibrary` now exposes canonical workflow output primitives:

- `MutationEffect` (`OptionSet`)
- `MutationOutcome<Value>`

### Signature pattern

```swift
@MainActor
func mutate(...) async throws -> MutationOutcome<Value>
```

### RecipeActionService example

```swift
func create(...) async throws -> MutationOutcome<Recipe>
func update(...) async throws -> MutationOutcome<Void>
func delete(...) async throws -> MutationOutcome<Void>
```

Effect mapping:

- `.recipeDataChanged` -> reload recipe widgets
- `.notificationPlanChanged` -> resync scheduled suggestions
- `.reviewPromptEligible` -> request review

### DiaryActionService example

```swift
func create(...) async throws -> MutationOutcome<Diary>
func update(...) async throws -> MutationOutcome<Void>
func add(...) async throws -> MutationOutcome<Diary>
func delete(...) async throws -> MutationOutcome<Void>
```

Effect mapping:

- `.diaryDataChanged` -> reload diary widget

## App Intent Adapter Compliance Checklist

1. Intents perform boundary concerns only:
   - parameter input
   - optional confirmation dialogs
   - entity resolution
2. Parsing/normalization/heuristics must live in `CookleLibrary`.
3. User-driven mutations must go through workflow services.
4. Intents should not own update-vs-create or find-vs-not-found domain branching.
5. Route vocabulary must use shared `CookleRoute*` APIs.

### Suggested follow-up adjustments

- Keep `TagIntentSupport` as a boundary helper for now; consider moving named
  lookups into workflow services if branching grows.
- Consider a shared recipe photo selection helper in `CookleLibrary` to reduce
  adapter duplication.
