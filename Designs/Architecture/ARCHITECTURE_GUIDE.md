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
- [ADR 0008](../Decisions/0008-adopt-package-consumer-boundaries.md)

## Responsibility Boundaries

<!-- markdownlint-disable MD013 -->
| Layer | Owns | Must not own |
| --- | --- | --- |
| Domain (`CookleLibrary`) | SwiftData schema, public `*Operations` facades, internal mutation/query collaborators, predicates, route helpers, validation, canonical mutations, canonical search, mutation effect hints | Widget reloads, notification registration, review prompts, deep-link delivery, App Intent result shaping, SwiftUI presentation state |
| Adapter (`Cookle`, `Widgets`, `Watch`, App Intents) | Parameter parsing, platform API calls, dependency wiring, route intake, follow-up orchestration after shared mutations, App Intent result mapping | Re-implementing recipe, diary, tag, or reset mutation rules |
| View (SwiftUI) | Focus state, sheets, dialogs, navigation state, screen-scoped `@Observable` models, display formatting, view composition | Canonical business validation, mutation rules, notification scheduling, widget reload coordination |
<!-- markdownlint-enable MD013 -->

## Source Layout

Cookle follows the Incomes source-layout direction by making architecture
areas visible in paths instead of keeping reusable app code in a broad
`Common` folder.

- `Cookle/Sources/App` contains app entry points, app-level App Intents,
  app-wide support types, and generic mutation workflow adapters.
- `Cookle/Sources/Features` contains product feature surfaces such as recipe,
  diary, photo, tag, search, settings, notifications, debug, and main
  navigation.
- `Cookle/Sources/Platform` contains app-side Apple framework and package
  integration such as runtime assembly, app group route storage, WidgetKit
  reloads, WatchConnectivity delivery, logging, monetization, and image
  processing.
- `Cookle/Sources/SharedUI` contains reusable app-target UI components,
  modifiers, styles, navigation environment helpers, text support, and TipKit
  definitions.
- `CookleLibrary/Sources/<Capability>` contains shared-library capabilities
  such as `Recipe`, `Diary`, `Photo`, `Tag`, `Navigation`, `Persistence`,
  `Preferences`, `Mutation`, `DataManagement`, `Notification`,
  `CookingSession`, and `Widgets`.
- `Widgets/Sources/App` contains widget entry wiring, while
  `Widgets/Sources/Features` contains individual widget implementations.
- `Watch/Sources/App` contains watch app entry wiring,
  `Watch/Sources/Features` contains watch UI, and
  `Watch/Sources/Platform` contains WatchConnectivity transport.
- `CookleLibrary/Tests/Default/<Capability>` mirrors the shared-library
  capability split.

## Package Consumer Boundaries

Cookle adopts shared packages by target responsibility, not by superficial
symmetry with sibling apps.

- `Cookle` is the full-app `MHPlatform` adopter because the app target owns
  runtime bootstrap, ads, StoreKit, license presentation, review flow, mutation
  follow-up, and route delivery wiring.
- `CookleLibrary` adopts `MHPlatformCore` for core-safe route, preference,
  persistence-maintenance, and logging contracts. It must not depend on
  `MHPlatform`, `MHAppRuntime`, app-runtime split products, MHUI, or MHDesign.
- `Cookle` adopts full `MHUI` on `1.20.0..<2.0.0` for its root theme and
  selected presentation primitives. It selects the standard Mist palette once
  at the app root. Existing metrics use MHUI's MHDesign re-export, without a
  separate direct MHDesign product link.
  [ADR 0009](../Decisions/0009-adopt-full-mhui-in-main-app.md) records the
  accepted main-app presentation boundary.
- `Widgets`, `Watch`, and App Intents call Cookle shared APIs first. They stay
  off app-runtime umbrellas. The companion presentation evaluation in
  [ADR 0010](../Decisions/0010-evaluate-mhui-for-companion-surfaces.md) retains
  native WidgetKit composition and defers Watch MHUI adoption because its
  standard surface failed the watchOS readability comparison.
- Cookle does not keep a generic utility package dependency. Small app-owned
  helper behavior stays local, while generic utilities and thin host-app
  presentation shortcuts remain outside MHUI.

## Presentation Adoption

Recipe Detail places the photo, compact facts, and cooking entry before the
ingredients and unframed instructions. MHUI supplies screen spacing, reading
headers, grouped rows, adaptive ingredient values, and semantic action styles.
Dates and secondary actions occupy the closing area. Cookle retains content,
routes, action handlers, and native presentations. Shared recipe sections
default to native presentation for search and Intent snippets.

Recipe browsing and editing, diaries, search, tags, settings, photo metadata,
and diagnostics use native List and Form chrome. These are complete adoption
routes that preserve native rows, sections, selection, swipe actions, fields,
focus, and keyboard behavior. Cooking and the photo collection use screen
composition; detached
recipe editors use input chrome on their native keyboard-resizing canvas.
Cooking presents one progress indicator and an unframed current instruction,
followed by step navigation and the grouped timer controls. Standard text
sizes retain native paging; accessibility sizes use natural-height text in
the screen scroll view and return to the instruction after a step change.
Media, system, and package-owned presentations retain their native appearance.
Ordinary content actions retain MHUI's non-glass default. Liquid Glass is an
explicit opt-in reserved for a bounded floating functional layer.
The [main-app rollout record](../Plans/mhui-app-rollout.md) documents these
choices and their verification limits. App-owned composition and behavior
remain local; MHUI is a presentation dependency, not a home for business logic
or generic utilities.

## Testing Boundary

- Keep repository-owned unit tests in `CookleLibrary/Tests/Default`.
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

- `Cookle/Sources/Features/Main/State/MainNavigationRouter.swift`
- `Cookle/Sources/Features/Recipe/Models/RecipeFormModel.swift`
- `Cookle/Sources/Features/Recipe/Services/RecipeFormSaveCoordinator.swift`
- `Cookle/Sources/Features/Diary/Models/DiaryFormModel.swift`
- `Cookle/Sources/Features/Diary/Services/DiaryFormSaveCoordinator.swift`
- `Cookle/Sources/Features/Settings/Models/SettingsScreenModel.swift`

Prefer this over `ObservableObject`, `EnvironmentObject`, or pushing
screen-local sequencing into a broader router.

## Canonical Mutation Flow

`View or App Intent` -> `app adapter/service` -> `CookleLibrary Operations` ->
`MutationOutcome<Value>` -> `app-side follow-up`

The current app-side mutation adapters are:

- `Cookle/Sources/Features/Recipe/Services/RecipeActionService.swift`
- `Cookle/Sources/Features/Diary/Services/DiaryActionService.swift`
- `Cookle/Sources/Features/Photo/Services/PhotoActionService.swift`
- `Cookle/Sources/Features/Tag/Services/TagActionService.swift`
- `Cookle/Sources/Features/Settings/Services/SettingsActionService.swift`

Those adapters may coordinate widget reloads, notification refreshes, and
review prompting after a shared mutation succeeds, but the mutation rules and
effect hints belong in `CookleLibrary`.

## App Intent Mapping

App Intents are adapters, not a second domain layer.

Preferred flow:

`App Intent parameter parsing` -> `same app adapter/service` ->
`same CookleLibrary Operations API`

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

- `CookleLibrary/Sources/Mutation/MutationOutcome.swift`
- `CookleLibrary/Sources/Mutation/MutationEffect.swift`

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
- public Operations facades and internal mutation or validation collaborators
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
   - `Cookle/Sources/Features/Main/Services/MainRouteService.swift`
   - `Cookle/Sources/Features/Main/State/MainNavigationRouter.swift`
   Minimal plan:
   - keep `MainRouteService` focused on pipeline assembly, parsing, and inbox
     sources
   - keep `MainNavigationRouter` focused on navigation state application

2. Form screens should keep state in screen models instead of large view-local
   mutation code.
   Files:
   - `Cookle/Sources/Features/Recipe/Views/RecipeFormView.swift`
   - `Cookle/Sources/Features/Diary/Views/DiaryFormView.swift`
   - `Cookle/Sources/Features/Settings/Views/SettingsSidebarView.swift`
   Minimal plan:
   - keep views focused on UI composition and error presentation
   - keep form state, tip priority, and save sequencing in dedicated models and
     coordinators

3. Mutation follow-up hints must stay shared while platform side effects stay
   app-owned.
   Files:
   - `CookleLibrary/Sources/Recipe/RecipeFormOperations.swift`
   - `CookleLibrary/Sources/Diary/DiaryOperations.swift`
   - `CookleLibrary/Sources/Tag/TagOperations.swift`
   - `CookleLibrary/Sources/DataManagement/DataMaintenanceOperations.swift`
   Minimal plan:
   - keep effect-hint decisions in `CookleLibrary`
   - keep notification sync, widget reload, and review flow wiring in app-side
     adapters

4. Notification route delivery should stay adapter-owned without duplicating
   route meaning.
   Files:
   - `Cookle/Sources/Features/Notification/Services/NotificationService.swift`
   - `CookleLibrary/Sources/Navigation/*`
   Minimal plan:
   - keep payload decoding and delivery in notification adapters
   - keep route vocabulary and parsing shared in `CookleLibrary`

## Cooking interaction and transient state

Cooking on iPhone and iPad is reading-first: show the surrounding numbered
steps together, with materials alongside them when space permits. Selecting a
step supplies timer and Watch context; it is not a completion checkbox or a
requirement to reveal the next step. A focused presentation can still be useful
on constrained surfaces such as Apple Watch. Evaluate each surface separately.

Keep screen-only state in memory: the material list copied when a cooking view
opens, pending Diary prefill, presentation flags, and unsaved quick-registration
input. Do not add a persisted cooked status or per-step completion flags for
these interactions. The material copy may differ from an older resumed step
snapshot; closing and reopening the view refreshes materials from the recipe.
It is not a new cross-device material snapshot contract.

The existing cooking session snapshot remains separate. It persists to
UserDefaults and participates in Watch synchronization; ending it clears its
timer and sets its existing active flag to false. Do not remove or change that
storage/wire contract merely to change the reading UI. Future storage changes
must explicitly address relaunch recovery, stale updates and paired devices.

Registering a recipe from Diary selection is an explicit independent save.
Before saving, explain that the recipe survives cancellation of the later Diary.
Registration cancellation creates nothing. The post-cooking Diary form also
keeps its unsaved draft in memory so it cannot overwrite or clear a separately
saved Diary draft. Ordinary Diary entry retains its existing draft persistence;
an explicit Diary save still creates the normal database record.

## Primary destinations and explicit entry routes

Ordinary launch and the home route open Diary. Diary is the place to record and
revisit meals; its presentation can evolve without changing that entry policy.
Do not persist a last-selected tab as a side effect of visual improvements.

Explicit destinations take precedence over the ordinary launch default:

| Entry | Destination and behavior |
| --- | --- |
| Recipe tab, recipe-list link | Browse saved recipes without creating a Diary |
| Recipe detail link, Recipe Widget, Open Recipe intent | Open the requested recipe |
| Cooking view | Read steps; optionally end and review a Diary draft |
| Diary tab, Diary link or Widget | Open the Diary list or requested entry |
| Photo tab or photo link | Browse saved photos or open the requested photo |
| Search or tag link | Open search or the requested category/ingredient |
| Settings link | Open the requested settings destination |

Photos remains a browsing surface. Its recipe-creation entry must say that it
adds a recipe; a name-only recipe can be enriched with photos later. Independent
photo capture and attach-later flows need a separate product decision.

Keep contextual recipe discovery and optional Diary recording available without
requiring either activity before the other. Route vocabulary and execution stay
in CookleLibrary; MainNavigationRouter selects the app destination. Changes to
system entry behavior require their own compatibility verification.

### Diary landing and recipe inspiration

The Diary landing screen separates today's saved record, recipe inspiration,
and chronological history. No record does not mean a meal is undecided, and a
recipe candidate is not evidence of a meal eaten. Opening a candidate navigates
to Recipe; only an explicit Diary save records a meal.

Candidates are a presentation window of up to three saved recipes, ordered by
modification date descending and name. Other Ideas advances the window; its
position stays in memory and resets when the ordered identifiers change. There
is no inferred nutrition, ingredient availability, meal plan, or cooked status.

Today uses the current calendar and refreshes on appearance, app activation,
and the system significant-time-change notification (including midnight).
Recent Meals contains up to three past records, with the remaining entries in
month groups. Today and recent records are not duplicated in the month groups;
future-dated records remain accessible there. Existing draft restoration and
explicit save behavior stay in the normal Diary form.
