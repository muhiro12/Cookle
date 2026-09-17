# Cookle

Cookle is a SwiftUI recipe manager that lets you collect dishes, log your cooking
history, and surface what to make next. The app ships on the App Store and this
repository contains the full iOS project together with its shared Swift package.

[Available on the App Store](https://apps.apple.com/app/id6483363226)

## Features

- Personal recipe database backed by SwiftData models for names, photos,
  ingredients, steps, categories, servings, timings, and notes.
- Cooking diary that organizes breakfasts, lunches, and dinners per day so you
  can reflect on what you prepared.
- Dedicated photo gallery that separates imported images from Image Playground
  creations while preserving stored photo assets even after they are unlinked
  from recipes.
- Ingredient and category tag management with search and filtering to keep large
  collections tidy.
- Full-text search across recipe names, ingredients, and categories with smart
  handling of short and long queries.
- Optional iCloud sync and data deletion controls that stay behind a
  subscription paywall managed in Settings.
- App Shortcuts and App Intents for opening the app, running searches, showing
  the last or a random recipe, and creating diary entries.
- Image Playground integration (iOS 18.1+) to generate dish photos from recipe
  content.
- Google Mobile Ads monetization and StoreKit-based subscriptions configured
  through MHPlatform runtime defaults.
- Remote configuration fetch that can require users to update before continuing,
  keeping deployed binaries aligned with server rules.
- Developer utilities including a regular-width debug tab and preview helpers
  that seed SwiftData models for SwiftUI previews.

## Project structure

- `Cookle/` – main SwiftUI application target with feature-based sources,
  platform wiring, remote-configuration adapters, and target configuration.
  App entry code lives in `Sources/App`, product surfaces live in
  `Sources/Features`, Apple-framework glue lives in `Sources/Platform`, and
  reusable target-local UI lives in `Sources/SharedUI`.
- `CookleLibrary/` – shared Swift package that exposes SwiftData models,
  Operations facades, predicates, migrations, and utilities used by the app and
  intents. Source and tests are organized by capability.
- `Widgets/` – home-screen widget extension target built on top of
  `CookleLibrary`.
- `Watch/` – watch companion target for the active cooking session.
- `MHPlatform` – shared app-runtime package family. The `Cookle` app
  intentionally adopts the default `MHPlatform` umbrella surface, while
  `CookleLibrary` stays on `MHPlatformCore` for core-safe shared logic.
- `MHUI` / `MHDesign` – shared presentation package family. `Cookle` adopts
  full MHUI for its root theme and selected presentation primitives, with
  existing metrics accessed through the MHDesign re-export. Product-specific
  screen composition stays in the app target.
- `Designs/Architecture/` – current architecture rules and placement guidance.
- `Designs/Decisions/` – architecture decision records that capture why major
  design choices were made.
- `Designs/Overviews/` – current project snapshot and product overview.
- `CookleLibrary/Tests/Default/` – package tests for public Operations contracts,
  reusable utilities, preferences, photo sources, and shared sub-object logic.
- `ci_scripts/` – automation helpers used by Xcode Cloud and CI pipelines to
  inject secrets and configure the build environment.

## Technology stack

- Swift 6 toolchain with Xcode 26.3 project settings and a minimum deployment
  target of iOS 18.0.
- SwiftUI for all user interfaces, including adaptive tab navigation and preview
  infrastructure.
- SwiftData for persistence, schema migrations, and model container previews
  shared between the app and App Intents.
- AppIntents for Shortcuts support and automation workflows built on top of
  SwiftData entities.
- MHPlatform 1.x using the current consumer boundaries: the `Cookle` app target
  stays on the default `MHPlatform` umbrella, `CookleLibrary` stays on
  `MHPlatformCore`, and the repository keeps MHPlatform on the
  `1.13.0..<2.0.0` range to preserve verified subscription entitlement handling.
- MHUI `1.20.0..<2.0.0` through the full `MHUI` product. The main app uses
  the standard root theme with an explicit Linen palette, preserving Cookle's
  orange accent within MHUI's warm neutral surfaces. It uses composed
  recipe/cooking/photo screens, native List/Form chrome, and detached input
  chrome. Content actions keep MHUI's non-glass default; any floating action
  opts into Liquid Glass only at its bounded control layer. See the
  [screen rollout record](Designs/Plans/mhui-app-rollout.md) for presentation
  exceptions and verification coverage.
- Cookle does not keep a generic utility package dependency. Small app-owned
  helper behavior stays local, while generic utilities and thin host-app
  presentation shortcuts remain outside MHUI.
- MHPlatform-managed StoreKit, Google Mobile Ads, and license presentation
  delivered through Swift Package Manager.

## Architecture rules

Cookle follows Apple's app architecture closely, but keeps reusable logic in the
shared package so multiple targets can call the same workflows.

Primary records:

- [Architecture guide](Designs/Architecture/ARCHITECTURE_GUIDE.md)
- [Shared service design](Designs/Architecture/shared-service-design.md)
- [ADR 0001](Designs/Decisions/0001-adopt-shared-services-and-workflow-adapters.md)
- [Deletion policy audit](Designs/Overviews/cookle-data-deletion-policy-audit.md)
- [ADR 0007](Designs/Decisions/0007-adapt-incomes-june-boundaries.md)
- [ADR 0008](Designs/Decisions/0008-adopt-package-consumer-boundaries.md)
- [ADR 0009](Designs/Decisions/0009-adopt-full-mhui-in-main-app.md)
- [ADR 0010](Designs/Decisions/0010-evaluate-mhui-for-companion-surfaces.md)

- `CookleLibrary` owns shared SwiftData models, public `*Operations` facades,
  predicates, queries, validation, mutations, migrations, and route helpers.
- MHPlatform consumer boundaries are explicit in this repo: `Cookle` is the
  umbrella-app adopter, `CookleLibrary` stays on `MHPlatformCore`, and
  `Widgets`/`Watch` stay off the umbrella.
- MHUI consumer boundaries are explicit: only `Cookle` adopts full MHUI.
  `CookleLibrary` stays presentation-free and Widgets retains native WidgetKit
  composition. Watch adoption is deferred after a failed MHUI 1.18 readability
  comparison. Companion targets and App Intent implementations currently stay
  off MHUI/MHDesign dependencies; future adoption is evaluated per surface.
- `MHAppRuntime` remains available as an advanced app-root surface, but this
  repo does not use it as the default adoption path.
- Repository-owned unit tests stay concentrated in `CookleLibrary/Tests/Default`.
- The repository does not maintain a separate `CookleTests` unit test target;
  app adapters are verified through `Cookle` builds plus shared-library tests.
- The `Cookle` app target owns workflow services such as
  `RecipeActionService`, `DiaryActionService`, `PhotoActionService`,
  `TagActionService`, and `SettingsActionService` that add app-only side
  effects after shared mutations.
- The root `CookleAppAssembly` centralizes model-container wiring, app service
  graph assembly, runtime bootstrap, and environment injection for the live app
  and SwiftUI previews.
- App startup and foreground refreshes are driven through
  `MHAppRuntimeBootstrap` and `MHAppRuntimeLifecyclePlan` instead of ad-hoc
  `scenePhase` handlers.
- SwiftUI views and App Intents call workflow services for commands instead of
  mutating models directly, and delivery surfaces call `*Operations` facades
  instead of service collaborators for shared business use cases.
- `RecipeOperations.search` is the canonical recipe search API used by views,
  intents, and widgets.
- Route parsing and execution stay shared so deep links, widgets, and intents
  speak the same navigation language through a single `MHAppRoutePipeline`.
- Mutation follow-up uses `MHMutationWorkflow.runThrowing(..., adapterValue:)`,
  `MHMutationProjectionStrategy`, and `MHReviewFlow` instead of app-local
  wrapper layers around successful mutations.
- App-owned preference persistence extends `MHPreferenceDescriptors`, and the
  repository keeps `CookleUserDefaultsKeys` as the central key catalog plus a
  single known-descriptor catalog for lifecycle cleanup and storage audits.
- Route meaning, notification copy and delivery meaning, review eligibility,
  and mutation-effect interpretation remain app-owned even when orchestration
  uses MHPlatform shells.

## Data model overview

CookleLibrary defines all persisted entities so the app, intents, and previews
share the same schema.

- `Recipe` stores the core cooking data, maintains relationships to photos,
  ingredients, categories, diaries, and tracks timestamps for sync logic.
- `Diary` captures a specific day along with ordered `DiaryObject` children that
  tag meals as breakfast, lunch, or dinner.
- `Photo` stores binary image data, the capture source, and reverse links to the
  recipes using it, enabling shared galleries.
- `Category` and `Ingredient` models act as tags for recipes, and provide
  predicates for filtering and App Intent queries.
- `DiaryObject`, `PhotoObject`, and `IngredientObject` are parent-owned
  structural rows, while `Recipe`, `Diary`, `Photo`, `Category`, and
  `Ingredient` are the main persisted root or shared records.
- The schema is versioned through `CookleMigrationPlan`, making room for future
  migrations without data loss.

## App Shortcuts and automation

Cookle exposes several intents so users can automate their workflows.

- `CookleShortcuts` registers the app shortcuts and updates model containers
  based on the current iCloud setting.
- Recipe intents cover open, create, update, delete, search, last-opened, and
  random suggestions, with mutations routed through `RecipeActionService`.
- Diary intents cover create, update, delete, add-to-today, and show flows, and
  use `DiaryActionService` for shared command handling.
- Tag rename intents wrap `TagActionService`. Category delete now uses the same
  shared action flow as the product UI, and ingredient delete now succeeds only
  when the ingredient is unused.
- Photo delete is exposed only from photo-centric UI, and it discloses how many
  linked recipe photo rows will be removed before deleting the asset.
- Settings and navigation intents open the same route-based destinations used by
  deep links and widgets.
- On iOS 26.0 and later, recipe inference uses Foundation Models when available
  and falls back to deterministic extraction when the model is unavailable or
  cannot produce a meaningful result.

## Deep links

Cookle uses a route-based deep-link system shared by the app and widgets.

- Custom scheme: `cookle://...`
- Universal Links: `https://muhiro12.github.io/Cookle/...`

Supported routes:

- `home`
- `diary`
- `diary/YYYY-MM-DD`
- `recipe`
- `recipe?id=<base64PersistentIdentifier>`
- `photo`
- `photo?id=<base64PersistentIdentifier>`
- `tag/category`
- `tag/category?id=<base64PersistentIdentifier>`
- `tag/ingredient`
- `tag/ingredient?id=<base64PersistentIdentifier>`
- `search`
- `search?q=<query>`
- `settings`
- `settings/subscription`
- `settings/license`

Legacy widget URLs such as `cookle://widget/diary` are no longer supported.
Universal Links require Apple App Site Association (AASA) deployment for
`muhiro12.github.io`.

## Monetization, sync, and configuration

- A StoreKit subscription unlocks premium features such as iCloud sync, and the
  app observes the runtime's verified entitlement state independently of product
  catalog metadata. Unknown state preserves existing preferences; active state
  preserves the user's iCloud choice, and inactive state disables iCloud sync.
- Settings surfaces the subscription paywall, iCloud toggle, and bulk delete
  controls while guarding destructive actions behind confirmation dialogs.
- Remote configuration is loaded from GitHub to determine whether the current
  build must force an update before the main UI is shown.
- Root lifecycle tasks refresh remote configuration, notification schedules,
  and pending routes during launch and foreground re-entry. Subscription changes
  update local preferences as soon as the runtime publishes a resolved state.
- Google Mobile Ads native placements are embedded through the shared runtime so
  ad units can be refreshed from a single place. Placements use `MHNativeAdSize`
  and omit the whole section when the cached subscription or runtime availability
  suppresses ads.

## Getting started

1. Clone the repository and open the workspace directory.
2. Open `Cookle.xcodeproj` in Xcode 26.3 or later and select the **Cookle**
   scheme.
3. Build and run on an iOS 18 simulator or device.

The monetization identifiers live in
`Cookle/Sources/Platform/CookleMonetizationConfiguration.swift`. They
are source-controlled production identifiers, not local-only credentials.

## Testing

- Repository-owned unit tests stay in `CookleLibrary/Tests/Default`.
- `Cookle`, `Widgets`, and App Intents are verified through app builds plus
  shared-library tests instead of a separate app unit test target.
- Use the Xcode-native integration available in the agent environment for
  Apple build, test, run, Simulator, runtime-log, Preview, live UI, and
  screenshot evidence.
- For app compile checks, use its build capability with project
  `Cookle.xcodeproj`, scheme `Cookle`, and a discovered iOS Simulator
  destination.
- For shared-library tests, use its test capability with the `CookleLibrary`
  scheme and a compatible discovered destination.
- For Watch builds and previews, use the shared `Watch` scheme and a
  discovered watchOS Simulator destination. Verify paired delivery separately.
- For runtime or UI-sensitive checks, add a targeted run, runtime-log review,
  Preview rendering when appropriate, and live UI or screenshot evidence.
- Run retained repository rule checks after Xcode-native build/test evidence:

  ```bash
  bash ci_scripts/tasks/check_repository_rules.sh
  ```

- Run the manual unused code audit only after an Xcode-native build has
  refreshed a supported DerivedData index:

  ```bash
  bash ci_scripts/tasks/check_unused_code.sh
  ```

## Continuous integration

- `ci_scripts/ci_post_clone.sh` adjusts Xcode defaults for plugin validation
  inside automated builds.

The repository contract is Xcode-native-first:
Direct entrypoints live in `ci_scripts/tasks/`, shared shell helpers live in
`ci_scripts/lib/`, and `ci_scripts/ci_post_clone.sh` is reserved for external
post-clone CI setup.

- The available Xcode-native integration owns Apple build, test, run,
  Simulator, runtime-log, Preview, live UI, and screenshot evidence.
- `bash ci_scripts/tasks/check_environment.sh --profile <swiftlint|rules>`
  diagnoses missing local prerequisites before retained shell checks.
- `bash ci_scripts/tasks/format_swift.sh` is the explicit SwiftLint autofix
  step to run after Swift edits.
- `bash ci_scripts/tasks/check_repository_rules.sh` runs retained SwiftLint and
  static architecture checks that are not naturally covered by the available
  Xcode-native integration.
- Xcode Cloud owns formal CI builds, tests, and archives.
- Release UI smoke auditing is intentionally separate from the normal verify
  gate. Use the global `$xcode-ui-smoke-auditor` skill and the
  [release UI smoke audit guide](Designs/Architecture/release-ui-smoke-audit.md)
  when a release or UI-sensitive change needs live Simulator evidence.
- `bash ci_scripts/tasks/check_unused_code.sh` runs the opt-in Periphery audit
  after an Xcode-native build has refreshed a supported index store.

SwiftLint is resolved from the `SimplyDanny/SwiftLintPlugins` package declared
in `Cookle.xcodeproj`. The repository scripts do not require a separately
installed `swiftlint` binary on your `PATH`.

Before running retained repository rules, diagnose the local prerequisites:

```sh
bash ci_scripts/tasks/check_environment.sh --profile rules
```

After Swift edits, run the explicit autofix step:

```sh
bash ci_scripts/tasks/format_swift.sh
```

Then run retained repository rules:

```sh
bash ci_scripts/tasks/check_repository_rules.sh
```

If you prefer to run the SwiftLint steps directly:

```sh
bash ci_scripts/tasks/format_swift.sh
bash ci_scripts/tasks/lint_swift.sh
```

## Unused code audit (Periphery)

Periphery is an opt-in manual audit tool in this repository. It is not part of
the standard Xcode-native build/test and retained-rule flow.

Install `periphery` manually before using the audit task. For example:

```sh
brew install periphery
```

Then build the `Cookle` scheme through the available Xcode-native integration.
The audit task uses `PERIPHERY_INDEX_STORE_PATH` when set. Otherwise, it
selects the index with the most recently modified versioned unit artifacts
across the repository shared DerivedData location and matching directories
under Xcode's default DerivedData root.

Run the audit after the Xcode-native build completes:

```sh
bash ci_scripts/tasks/check_unused_code.sh
```

The repository keeps stable scan options, including `skip_build`, in
`.periphery.yml`; the task passes the selected index store explicitly. Set
`PERIPHERY_INDEX_STORE_PATH` to an existing DataStore directory when Xcode
uses another DerivedData location. Relative override paths are resolved from
the repository root. This repository does not maintain a Periphery baseline
file. Keep intentional framework entry points with `// periphery:ignore` when
needed.

### Build output layout

Cookle helper scripts may write disposable cache data under `.build/ci/shared/`.
Xcode-native build and test evidence is owned by the active integration. The
repository keeps `.build/ci/shared/DerivedData` as a compatibility DerivedData
location, while opt-in follow-up tools such as Periphery can also use Xcode's
default DerivedData index.

## Screenshots

| iPhone | iPhone | iPhone |
| --- | --- | --- |
| ![iPhone screenshot showing recipe list](https://github.com/user-attachments/assets/d1d874c5-b2d9-4342-873e-7efdfa88e865) | ![iPhone screenshot showing recipe detail](https://github.com/user-attachments/assets/ae8f05e2-5fe6-4123-a049-f56799ccc759) | ![iPhone screenshot showing diary view](https://github.com/user-attachments/assets/ace07047-2005-4dd3-8dce-f3d694832e83) |

| iPad |
| --- |
| ![iPad screenshot showing recipe grid](https://github.com/user-attachments/assets/9fd3da4b-3739-4ac5-b581-48adbbbb7143) |
| ![iPad screenshot showing recipe detail](https://github.com/user-attachments/assets/1b5364d0-75a8-4f44-9fa4-0b529fdef5f5) |
| ![iPad screenshot showing diary view](https://github.com/user-attachments/assets/e1e6aac3-8563-4560-be5d-ef473bf63e10) |
