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
  creations while keeping them linked to recipes.
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
  through lightweight wrapper packages.
- Remote configuration fetch that can require users to update before continuing,
  keeping deployed binaries aligned with server rules.
- Developer utilities including a debug tab, menu launcher, and preview helpers
  that seed SwiftData models for SwiftUI previews.

## Project structure

- `Cookle/` – main SwiftUI application target with screens, intents,
  configuration, and wrapper integrations.
- `CookleLibrary/` – shared Swift package that exposes SwiftData models,
  services, predicates, migrations, and utilities used by the app and intents.
- `Widgets/` – home-screen widget extension target built on top of
  `CookleLibrary`.
- `CookleLibrary/Tests/` – package tests for reusable utilities such as
  preferences, photo sources, and shared sub-object logic.
- `ci_scripts/` – automation helpers used by Xcode Cloud and CI pipelines to
  inject secrets and configure the build environment.

## Technology stack

- Swift 6 toolchain with Xcode 26.3 project settings and a minimum deployment
  target of iOS 17.0.
- SwiftUI for all user interfaces, including adaptive tab navigation and preview
  infrastructure.
- SwiftData for persistence, schema migrations, and model container previews
  shared between the app and App Intents.
- AppIntents for Shortcuts support and automation workflows built on top of
  SwiftData entities.
- StoreKit, Google Mobile Ads, License List, and SwiftUtilities delivered
  through lightweight wrapper packages and Swift Package Manager.

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
- The schema is versioned through `CookleMigrationPlan`, making room for future
  migrations without data loss.

## App Shortcuts and automation

Cookle exposes several intents so users can automate their workflows.

- `CookleShortcuts` registers the app shortcuts and updates model containers
  based on the current iCloud setting.
- Recipe intents cover search, last-opened, and random suggestions backed by
  `RecipeService` queries.
- The `CreateDiaryIntent` lets Shortcuts create diary entries by converting
  `RecipeEntity` selections back to SwiftData models.
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
- Google Mobile Ads native placements are embedded through the shared controller
  so ad units can be refreshed from a single place.

## Getting started

1. Clone the repository and open the workspace directory.
2. Provide `Cookle/Configurations/Secret.swift`, which is excluded from version
   control and injected in CI through `SECRETS_BASE64`.
3. Open `Cookle.xcodeproj` in Xcode 26.3 or later and select the **Cookle**
   scheme.
4. Build and run on an iOS 17 simulator or device.

### Secret.swift template

Create `Cookle/Configurations/Secret.swift` with your own identifiers for ads
and subscriptions before building:

```swift
enum Secret {
    static let adUnitID = "ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy"
    static let adUnitIDDev = "ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz"
    static let groupID = "group.com.example.cookle"
    static let productID = "com.example.cookle.subscription"
}
```

## Testing

- Use the standard CI entry point:

  ```bash
  bash ci_scripts/run_required_builds.sh
  ```

- Run the app build directly:

  ```bash
  bash ci_scripts/build_cookle.sh
  ```

- Run the shared package tests directly:

  ```bash
  bash ci_scripts/test_cookle_library.sh
  ```

## Continuous integration

- `ci_scripts/ci_post_clone.sh` decodes `SECRETS_BASE64` into
  `Cookle/Configurations/Secret.swift` and adjusts Xcode defaults for plugin
  validation inside automated builds.
- Provide the same environment variable when running builds on CI providers so
  ads and StoreKit configuration compile correctly.

### Build output layout

Cookle CI helper scripts keep generated files under `build/` and separate them
by responsibility:

- `build/work/` stores temporary xcodebuild data such as `DerivedData`,
  `build/work/results/*.xcresult`, and temporary files.
- `build/cache/` stores SwiftPM and compiler caches.
- `build/logs/` stores script execution logs.

You can override the root directory with `BUILD_ROOT`:

```bash
BUILD_ROOT=/tmp/cookle-build bash ci_scripts/build_cookle.sh
```

When a script exits, it always prints the result bundle path, log path, and the
re-run command.

## Screenshots

| iPhone | iPhone | iPhone |
| --- | --- | --- |
| ![iPhone screenshot showing recipe list](https://github.com/user-attachments/assets/d1d874c5-b2d9-4342-873e-7efdfa88e865) | ![iPhone screenshot showing recipe detail](https://github.com/user-attachments/assets/ae8f05e2-5fe6-4123-a049-f56799ccc759) | ![iPhone screenshot showing diary view](https://github.com/user-attachments/assets/ace07047-2005-4dd3-8dce-f3d694832e83) |

| iPad |
| --- |
| ![iPad screenshot showing recipe grid](https://github.com/user-attachments/assets/9fd3da4b-3739-4ac5-b581-48adbbbb7143) |
| ![iPad screenshot showing recipe detail](https://github.com/user-attachments/assets/1b5364d0-75a8-4f44-9fa4-0b529fdef5f5) |
| ![iPad screenshot showing diary view](https://github.com/user-attachments/assets/e1e6aac3-8563-4560-be5d-ef473bf63e10) |
