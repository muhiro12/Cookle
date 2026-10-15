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

Recipe suggestions adapt to the first independent app open in each meal window
(before 11:00, 11:00-16:00, and from 16:00). The last 14 local dates are kept in one
device-local preference value. A meal needs at least two observed days and at
least half of the independent-use days; its median time is rounded down to
:00 or :30. Notification opens do not train the time, but renew that meal's
14-day activity limit. Suggestions are capped at one per meal and three per day.

Choose Off, At a set time (one suggestion per day), or Adaptive. New installations
prefer Adaptive; upgrades preserve Off or the existing fixed hour and minute.
The choice is separate from iOS permission. When permission is unavailable, the
choice is kept and disabled until permission is granted. Fixed mode also learns
meal times; Off records no usage. Adaptive schedules nothing until enough history
exists. Opening a meal window skips its remaining adaptive suggestion that day;
mode and time changes replace managed requests within the existing 14-day horizon.

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
  `1.16.0..<2.0.0` range for consent-managed ads, native ad layouts, and the
  synchronous preference registry.
- MHUI `2.3.0..<3.0.0` through the full `MHUI` product. The main app applies
  the neutral standard root theme and its native appearance once, keeping
  Cookle's orange accent app-owned as the native control tint. Product
  collections and editors use MHUI content List/Form presentation,
  recipe/cooking/diary/photo screens use stack composition, and settings and
  diagnostics keep native grouping and row geometry with MHUI's themed canvas
  and row surfaces.
  Content actions keep MHUI's non-glass default; any floating action opts into
  Liquid Glass only at its bounded control layer. See the
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

- [Architecture guide](Designs/Architecture/ARCHITECTURE_GUIDE.md), including
  [live SwiftData read ownership](Designs/Architecture/ARCHITECTURE_GUIDE.md#live-app-data-flow)
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
- Ordinary package regression tests stay in `CookleLibrary/Tests/Default`;
  synthetic future-schema observations stay in `CookleLibrary/Tests/SchemaResearch`.
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
- Live search uses feature-owned `@Query` with the shared `RecipePredicate`
  and `RecipeOperations.browse` ordering. `RecipeOperations.search` exposes
  the same matching and ordering for one-shot intent and widget reads.
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
  ad units can be refreshed from a single place. Placements choose an
  `MHNativeAdLayout` (`.compact` in lists, `.media` on recipe detail), take the
  available width at their natural height, and omit the whole section when the
  cached subscription or the runtime's `canDisplayAds` suppresses ads.
- The live runtime opts into MHPlatform's consent-managed ads. After premium
  status resolves as inactive, Google's User Messaging Platform refreshes
  consent each session and presents a form only when required. The runtime uses
  the SDK's latest ad-request eligibility, including its previous-session state
  while the update runs, and suppresses ads when premium becomes active.
  Settings shows Privacy Options when the platform requires that entry point
  and prevents overlapping presentations. Rejecting personalized advertising
  does not itself determine whether the SDK permits an ad request.

## Getting started

1. Clone the repository and open the workspace directory.
2. Open `Cookle.xcodeproj` in Xcode 26.3 or later and select the **Cookle**
   scheme.
3. Build and run on an iOS 18 simulator or device.

The monetization identifiers live in
`Cookle/Sources/Platform/CookleMonetizationConfiguration.swift`. They
are source-controlled production identifiers, not local-only credentials.
The AdMob application identifier lives in `Cookle/Configurations/Info.plist`.
Create and publish the applicable Privacy & messaging forms for that Cookle
application in AdMob; integrating UMP alone does not configure those forms.
See [Google's UMP setup guide](https://developers.google.com/admob/ios/privacy).
For Simulator region checks, Debug builds accept
`COOKLE_ADS_CONSENT_DEBUG_GEOGRAPHY=eea`, `regulatedUSState`, or `other`.
Keep Cookle's application identifier when validating its account configuration;
a successful form with Google's sample application identifier only proves the
test integration.

## Testing

Choose evidence for the changed boundary; library tests, consumer builds,
retained rules, and runtime checks prove different things. Discover current
schemes and destinations from the project rather than assuming a saved selection.
Before switching Xcode selection, record it. After verification, stop runs and
interaction sessions started for the check, restore the original scheme, then
rediscover and restore its destination. Report any restoration failure.

- Run the complete `CookleLibrary` test plan for ordinary regression checks.
  It contains all `CookleLibraryTests` and requires zero raw warnings.
- Run the complete `CookleSchemaResearch` plan for the two synthetic future-store
  observations in `CookleSchemaResearchTests`. Run it initially and again when
  the declared schema, storage, model, dependency, or fixture inputs change, or
  when Xcode, Swift, the Simulator SDK, or the test runtime changes.
  The input scope is recorded in `ci_scripts/push_verification.json`.
  Preserve its raw logs, diagnostic counts, native results, and assertion meaning.
  A passing observation characterizes possible data loss; it does not prove safety.
  See the [store upgrade paths](Designs/Overviews/cookle-store-upgrade-paths.md#6-synthetic-downgrade-exposes-a-data-loss-risk)
  before publishing a schema change.
- `Cookle`, `Widgets`, and App Intents are verified through app builds plus
  shared-library tests instead of a separate app unit test target.
- Use the Xcode-native integration available in the agent environment for
  Apple build, test, run, Simulator, runtime-log, Preview, live UI, and
  screenshot evidence.
- For app compile checks, use its build capability with project
  `Cookle.xcodeproj`, scheme `Cookle`, and a discovered iOS Simulator
  destination.
- For shared-library tests, use its test capability with the `CookleLibrary`
  scheme, explicitly selecting the required test plan, and a compatible discovered
  destination.
- For public `CookleLibrary` APIs, `*Operations`, shared wire contracts,
  SwiftData schema, or adapter-facing changes, also build the `Cookle` consumer.
- For widget changes, build the `Widgets` scheme with a discovered iOS
  Simulator destination.
- For Watch builds and previews, use the shared `Watch` scheme and a
  discovered watchOS Simulator destination. Verify paired delivery separately.
  Watch product linkage changes also require a `Cookle` embedding-target build.
- For runtime or UI-sensitive checks, add a targeted run, runtime-log review,
  Preview rendering when appropriate, and live UI or screenshot evidence.
- Run retained repository rule checks when the changed code affects their
  static boundaries; they complement Xcode-native build/test evidence:

  ```bash
  bash ci_scripts/tasks/check_repository_rules.sh
  ```

## Continuous integration

Follow existing Swift source style and the repository SwiftLint configuration.
Markdown follows the [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md).

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

## Build output layout

Cookle helper scripts may write disposable cache data under `.build/ci/shared/`.
Xcode-native build and test evidence is owned by the active integration. The
repository keeps `.build/ci/shared/DerivedData` as a compatibility DerivedData
location.

## Optional Local Push Verification

`ci_scripts/push_verification.json` declares the `Cookle` build, the complete
ordinary `CookleLibrary` plan, and retained rules. The Cookle adapter also requires
a separate schema-research observation matching the declared inputs and native
environment. An unrelated app-view or prose change can reuse that observation;
a storage or environment change requires another research run.
The optional local hook invokes
`python3 ci_scripts/lib/agent_verification.py push <remote-name> <remote-location>`.
It requires the installed `ci-verify-and-summarize` skill; set
`CI_VERIFICATION_SKILL` for a non-default installation. Missing helpers or
unsupported versions leave verification incomplete. Ordinary builds, rules,
and Xcode Cloud do not require the skill.

Set `CI_VERIFICATION_EVIDENCE=1` when capturing retained rules for a receipt.
This binds strict SwiftLint execution to the registered project artifact, tracked
package pin, and complete tracked Swift input list. Source searches distinguish
no match from execution failure. The hook matches private `.git/push-verification`
evidence without rerunning QA or scanners. Follow the skill's
[receipt procedure](https://github.com/muhiro12/agent-skills/blob/main/ci-verify-and-summarize/references/push-verification.md)
for complete native results, zero diagnostics, full outgoing-history scan/review,
compatibility checks, and receipt refresh. Activation and publication are separate.

Capture the complete `CookleSchemaResearch` plan separately, without requesting
a clean-diagnostics QA record. After reviewing every raw warning/error candidate
against its exact passing assertion, preserve the observation with:

```sh
python3 ci_scripts/lib/schema_research.py record \
  --captured /path/to/research-capture \
  --review /path/to/diagnostic-review.json \
  --output /path/to/new-research-observation
```

The review binds each candidate to its raw line and hash, native test ID,
committed test source and hash, start/pass span, and contextual reason. The
observation retains the capture and native artifacts with `status: observed`
and `safety_proof: false`; it cannot satisfy ordinary zero-warning QA. Add its
store-relative `result.json` path to the private receipt under
`schema_research[<proposed-commit>]`. Missing or stale observations stop the
optional push hook without rerunning tests or hiding diagnostics.

## Screenshots

| iPhone | iPhone | iPhone |
| --- | --- | --- |
| ![iPhone screenshot showing recipe list](https://github.com/user-attachments/assets/d1d874c5-b2d9-4342-873e-7efdfa88e865) | ![iPhone screenshot showing recipe detail](https://github.com/user-attachments/assets/ae8f05e2-5fe6-4123-a049-f56799ccc759) | ![iPhone screenshot showing diary view](https://github.com/user-attachments/assets/ace07047-2005-4dd3-8dce-f3d694832e83) |

| iPad |
| --- |
| ![iPad screenshot showing recipe grid](https://github.com/user-attachments/assets/9fd3da4b-3739-4ac5-b581-48adbbbb7143) |
| ![iPad screenshot showing recipe detail](https://github.com/user-attachments/assets/1b5364d0-75a8-4f44-9fa4-0b529fdef5f5) |
| ![iPad screenshot showing diary view](https://github.com/user-attachments/assets/e1e6aac3-8563-4560-be5d-ef473bf63e10) |
