# Cookle Architecture Conformance Audit

Current as of April 17, 2026.

## Purpose

This note records whether the current repository still follows the accepted
Cookle architecture:

- `CookleLibrary` is the single source of truth for reusable business logic.
- `Cookle`, `Widgets`, and App Intents stay responsibility-thin as
  Apple-platform adapters.
- Repository-owned unit tests stay concentrated in `CookleLibrary/Tests`.

Authoritative design rules remain:

- [ADR 0001](../Decisions/0001-adopt-shared-services-and-workflow-adapters.md)
- [ADR 0002](../Decisions/0002-app-intents-are-adapters.md)
- [ADR 0003](../Decisions/0003-platform-adapters-stay-in-app-target.md)
- [ADR 0005](../Decisions/0005-adapter-failure-surfacing-contract.md)
- [ARCHITECTURE_GUIDE.md](../Architecture/ARCHITECTURE_GUIDE.md)
- [shared-service-design.md](../Architecture/shared-service-design.md)

## Conclusion

The repository is materially aligned with the intended architecture after the
current correction. Shared recipe browse/search behavior, persisted photo
ordering/removal rules, and primitive preference descriptor cataloging now live
in `CookleLibrary`, and the repository no longer carries a separate
`CookleTests` app unit test target.

## Conformant

### Shared business logic remains centralized

- `CookleLibrary` owns the shared model, mutation/query services, browse
  criteria, shared photo display/removal rules, and preference descriptor
  catalog.
- Representative files:
  - `CookleLibrary/Sources/Recipe/RecipeService.swift`
  - `CookleLibrary/Sources/Recipe/RecipeBrowseCriteria.swift`
  - `CookleLibrary/Sources/Recipe/RecipePhotoDisplay.swift`
  - `CookleLibrary/Sources/Common/CooklePreferenceCatalog.swift`

### Multiple targets still consume the same shared APIs

- The iOS app and widgets both depend on the local `CookleLibrary` package
  product from `Cookle.xcodeproj`.
- Representative files:
  - `Cookle/Sources/Common/CookleLibrary.swift`
  - `Widgets/Sources/Common/CookleLibrary.swift`
  - `Cookle.xcodeproj/project.pbxproj`

### Tests are library-centered

- Repository-owned unit tests are concentrated in `CookleLibrary/Tests`.
- `Cookle.xcodeproj` no longer defines a `CookleTests` unit test target.
- Verification now builds the `Cookle` scheme and runs `CookleLibrary` tests.
- Representative files:
  - `CookleLibrary/Tests/RecipeBrowseCriteriaTests.swift`
  - `CookleLibrary/Tests/RecipePhotoRemovalTests.swift`
  - `ci_scripts/tasks/verify_repository_state.sh`
  - `ci_scripts/tasks/check_test_posture.sh`

## Corrected Drift

### App-owned test posture drift

- Previous state:
  - The repository defined a `CookleTests` unit test target.
  - `verify_repository_state.sh` treated `test_app.sh` as the required app-side
    verification path.
  - App-owned tests had started to cover logic that should have been modeled as
    shared rules instead.
- Risk:
  - The repository contract contradicted the intended library-centered
    architecture and made it easy to keep durable logic in the app target.
- Current correction:
  - `CookleTests` and `test_app.sh` are removed.
  - Verification now uses `build_app.sh` plus `test_shared_library.sh`.
  - A dedicated `check_test_posture.sh` guardrail blocks reintroduction of the
    removed app test posture.

### Shared recipe browse and photo rule drift

- Previous state:
  - Recipe list sorting lived in an app-local browse helper.
  - Persisted photo ordering and removal rules lived in app-local helpers.
- Risk:
  - Different app surfaces could drift away from the canonical search and photo
    semantics expected across widgets, notifications, and intents.
- Current correction:
  - `RecipeService.search(context:criteria:)` owns canonical browse/search
    sorting.
  - `RecipePhotoDisplay` and `RecipePhotoRemovalBehavior` now live in
    `CookleLibrary`.
  - `RecipeService.removePhotoWithOutcome(...)` now owns the shared persisted
    photo mutation rule.

## Notes

- This audit does not introduce a new architecture policy. It records current
  conformance against the already accepted ADRs and guide documents.
- Future durable rules discovered in app adapters should be extracted into
  `CookleLibrary` instead of reintroducing target-local unit tests.
