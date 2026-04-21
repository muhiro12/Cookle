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
- `CookleLibrary/` – shared Swift package that exposes SwiftData models,
  services, predicates, migrations, and utilities used by the app and intents.
- `Widgets/` – home-screen widget extension target built on top of
  `CookleLibrary`.
- `MHPlatform` – shared app-runtime package family. The `Cookle` app
  intentionally adopts the default `MHPlatform` umbrella surface, while
  `CookleLibrary` stays on `MHPlatformCore` for core-safe shared logic.
- `Designs/Architecture/` – current architecture rules and placement guidance.
- `Designs/Decisions/` – architecture decision records that capture why major
  design choices were made.
- `Designs/Overviews/` – current project snapshot and product overview.
- `CookleLibrary/Tests/` – package tests for reusable utilities such as
  preferences, photo sources, and shared sub-object logic.
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
- MHPlatform 1.x using the 1.2 consumer pillars: the `Cookle` app target stays
  on the default `MHPlatform` umbrella, `CookleLibrary` stays on
  `MHPlatformCore`, and the repo keeps MHPlatform on the `1.0.0..<2.0.0` range
  with a checked-in `1.2+` resolved baseline.
- SwiftUtilities plus MHPlatform-managed StoreKit, Google Mobile Ads, and
  license presentation delivered through Swift Package Manager.

## Architecture rules

Cookle follows Apple's app architecture closely, but keeps reusable logic in the
shared package so multiple targets can call the same workflows.

Primary records:

- [Architecture guide](Designs/Architecture/ARCHITECTURE_GUIDE.md)
- [Shared service design](Designs/Architecture/shared-service-design.md)
- [ADR 0001](Designs/Decisions/0001-adopt-shared-services-and-workflow-adapters.md)
- [Deletion policy audit](Designs/Overviews/cookle-data-deletion-policy-audit.md)

- `CookleLibrary` owns shared SwiftData models, predicates, queries,
  validation, mutations, migrations, and route helpers.
- MHPlatform consumer boundaries are explicit in this repo: `Cookle` is the
  umbrella-app adopter, `CookleLibrary` stays on `MHPlatformCore`, and
  `Widgets` stay off the umbrella.
- `MHAppRuntime` remains available as an advanced app-root surface, but this
  repo does not use it as the default adoption path.
- Repository-owned unit tests stay concentrated in `CookleLibrary/Tests`.
- The repository does not maintain a separate `CookleTests` unit test target;
  app adapters are verified through `Cookle` builds plus shared-library tests.
- The `Cookle` app target owns workflow services such as
  `RecipeActionService`, `DiaryActionService`, `TagActionService`, and
  `SettingsActionService` that add app-only side effects after shared mutations.
- The root `CookleAppAssembly` centralizes model-container wiring, app service
  graph assembly, runtime bootstrap, and environment injection for the live app
  and SwiftUI previews.
- App startup and foreground refreshes are driven through
  `MHAppRuntimeBootstrap` and `MHAppRuntimeLifecyclePlan` instead of ad-hoc
  `scenePhase` handlers.
- SwiftUI views and App Intents call those workflow services for commands
  instead of mutating models directly.
- `RecipeService.search` is the canonical recipe search API used by views,
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
- Settings and navigation intents open the same route-based destinations used by
  deep links and widgets.
- FoundationModels hooks are stubbed for future recipe inference workflows once
  supported on iOS.

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
  app updates local state whenever the store inventory changes.
- Settings surfaces the subscription paywall, iCloud toggle, and bulk delete
  controls while guarding destructive actions behind confirmation dialogs.
- Remote configuration is loaded from GitHub to determine whether the current
  build must force an update before the main UI is shown.
- Root lifecycle tasks refresh subscription state, remote configuration,
  notification schedules, and pending routes during launch and foreground
  re-entry.
- Google Mobile Ads native placements are embedded through the shared runtime so
  ad units can be refreshed from a single place.

## Getting started

1. Clone the repository and open the workspace directory.
2. Open `Cookle.xcodeproj` in Xcode 26.3 or later and select the **Cookle**
   scheme.
3. Build and run on an iOS 18 simulator or device.

The monetization identifiers live in
`Cookle/Sources/Common/Platform/CookleMonetizationConfiguration.swift`. They
are source-controlled production identifiers, not local-only credentials.

## Testing

- Repository-owned unit tests stay in `CookleLibrary/Tests`.
- `Cookle`, `Widgets`, and App Intents are verified through app builds plus
  shared-library tests instead of a separate app unit test target.

- Use the recommended final gate:

  ```bash
  bash ci_scripts/tasks/verify_task_completion.sh
  ```

- Run required builds/tests based on local changes:

  ```bash
  bash ci_scripts/tasks/verify_repository_state.sh
  ```

- Run the app build directly:

  ```bash
  bash ci_scripts/tasks/build_app.sh
  ```

- Run the shared package tests directly:

  ```bash
  bash ci_scripts/tasks/test_shared_library.sh
  ```

## Continuous integration

- `ci_scripts/ci_post_clone.sh` adjusts Xcode defaults for plugin validation
  inside automated builds.

The repository contract is:
Direct entrypoints live in `ci_scripts/tasks/`, shared shell helpers live in
`ci_scripts/lib/`, and `ci_scripts/ci_post_clone.sh` is reserved for external
post-clone CI setup.

- `bash ci_scripts/tasks/check_environment.sh --profile <format|build|verify>`
  diagnoses missing local prerequisites before you start a tool-dependent flow.
- `bash ci_scripts/tasks/format_swift.sh` is the explicit SwiftLint autofix
  step to run after Swift edits and before the final verification gate.
- `bash ci_scripts/tasks/verify_task_completion.sh` is the non-destructive
  verification gate for Codex task completion.
- `bash ci_scripts/tasks/verify_repository_state.sh` checks the current
  repository state and still writes CI run artifacts.
- `bash ci_scripts/tasks/verify_pre_push.sh` is the optional local `pre-push`
  hook wrapper for the same non-destructive verification gate.

SwiftLint is resolved from the `SimplyDanny/SwiftLintPlugins` package declared
in `Cookle.xcodeproj`. The repository scripts do not require a separately
installed `swiftlint` binary on your `PATH`.

Before running the full verify gate, diagnose the local prerequisites:

```sh
bash ci_scripts/tasks/check_environment.sh --profile verify
```

After Swift edits, run the explicit autofix step:

```sh
bash ci_scripts/tasks/format_swift.sh
```

Then run the non-destructive full recheck:

```sh
bash ci_scripts/tasks/verify_task_completion.sh
```

For release-time verification or a clean-worktree full run, force the standard
verify entrypoint to execute all required checks:

```sh
CI_RUN_FORCE_FULL=1 bash ci_scripts/tasks/verify_task_completion.sh
```

If you only need the local `pre-push` wrapper shell:

```sh
bash ci_scripts/tasks/verify_pre_push.sh
```

If you prefer to run the SwiftLint steps directly:

```sh
bash ci_scripts/tasks/format_swift.sh
bash ci_scripts/tasks/lint_swift.sh
```

If you only need required builds/tests based on local changes:

```sh
bash ci_scripts/tasks/verify_repository_state.sh
```

If you only need the app build:

```sh
bash ci_scripts/tasks/build_app.sh
```

If you only need library tests:

```sh
bash ci_scripts/tasks/test_shared_library.sh
```

If you want an optional Git `pre-push` hook for the same repository flow, add a
local `.git/hooks/pre-push` script like this:

```sh
#!/usr/bin/env bash
set -euo pipefail

repository_root=$(git rev-parse --show-toplevel)
cd "$repository_root"

exec bash ci_scripts/tasks/verify_pre_push.sh
```

### Build output layout

Cookle CI helper scripts write all generated artifacts under `.build/ci/`.
Run-scoped outputs are stored in `.build/ci/runs/<RUN_ID>/` (summary, commands,
meta, logs, results, work), while shared caches and build state live in
`.build/ci/shared/` (`cache/`, `DerivedData/`, `tmp/`, `home/`).
Only the latest 5 runs under `.build/ci/runs/` are retained.
The entire `.build/ci` directory is disposable.

## Screenshots

| iPhone | iPhone | iPhone |
| --- | --- | --- |
| ![iPhone screenshot showing recipe list](https://github.com/user-attachments/assets/d1d874c5-b2d9-4342-873e-7efdfa88e865) | ![iPhone screenshot showing recipe detail](https://github.com/user-attachments/assets/ae8f05e2-5fe6-4123-a049-f56799ccc759) | ![iPhone screenshot showing diary view](https://github.com/user-attachments/assets/ace07047-2005-4dd3-8dce-f3d694832e83) |

| iPad |
| --- |
| ![iPad screenshot showing recipe grid](https://github.com/user-attachments/assets/9fd3da4b-3739-4ac5-b581-48adbbbb7143) |
| ![iPad screenshot showing recipe detail](https://github.com/user-attachments/assets/1b5364d0-75a8-4f44-9fa4-0b529fdef5f5) |
| ![iPad screenshot showing diary view](https://github.com/user-attachments/assets/e1e6aac3-8563-4560-be5d-ef473bf63e10) |
