# Cookle Architecture Conformance Audit

Reviewed on September 30, 2026 against the current Cookle sources, the Incomes
architecture guide, and
[Stally Issue 21](https://github.com/muhiro12/Stally/issues/21).

## Scope and Conclusion

Cookle remains aligned with `domain-in-library, adapters-in-targets` and the
SwiftData-first live app data flow. The review covers source placement, live
reads, selected-model propagation, relationship traversal, mutation entry
points, package consumers, test ownership, and architecture guidance.

Two app-local data-flow inconsistencies are corrected: Search no longer
retains a one-shot fetched collection in `@State`, and recipe Diary-history
rows now receive the current Diary through typed environment. The existing
diagnostic raw-deletion policy remains unresolved; the review does not claim
that every mutation path conforms.

Authoritative rules remain in the
[architecture guide](../Architecture/ARCHITECTURE_GUIDE.md),
[shared service design](../Architecture/shared-service-design.md), and accepted
[architecture decisions](../Decisions/0001-adopt-shared-services-and-workflow-adapters.md).

## Architectural Findings

### Align: Live Search Ownership

Previously, `SearchView` performed `RecipeOperations.search` only when search
text changed and stored its result in `@State`. Writes with unchanged search
text had no collection-refresh owner. `SearchResultsView` now owns the live
query; `SearchView` owns text, debounce, retry identity, and presentations.
The existing shared predicate and browse ordering preserve short-text tag
matching and localized alphabetical ordering. Query fetch errors retain a
visible retry path.

### Align: Selected Diary Propagation

`RecipeDiaryRow` was an initializer-based current-model exception among
environment-based rows. `RecipeDiariesSection` and `RecipeDiaryHistoryView`
now inject each current Diary. The row follows the same convention as
`DiaryLabel` and `RecipeLabel`; the route and relationship traversal are
unchanged.

### Keep: Feature Reads and Relationships

- `MainView` and `MainNavigationModel` own routes and selections, without a
  root query spanning unrelated features.
- Recipe, Diary, Photo, Tag, and form-selection surfaces own their queries.
  The guide's [read inventory](../Architecture/ARCHITECTURE_GUIDE.md#current-read-ownership)
  identifies the consuming surface and independent duplicate queries.
- `DiaryView` follows `Diary.objects` to recipes. Recipe sections, `TagView`,
  and `PhotoView` likewise traverse existing relationships instead of
  re-fetching those graphs.
- Selected models enter destination and row environments. Navigation
  selections are live references, not mirrored models.

### Adapt: Purpose-Specific Values and Adapters

`RecipeFormModel`, `DiaryFormModel`, form snapshots, mutation reviews, cooking
and Watch snapshots, archive records, and App Intent/inference entities have
different lifetimes or framework roles from live persistence models. Retain
them. `RecipeFormPresenter` keeps unsaved input alive across layout changes;
`RecipeFormNavigationView` supplies its source recipe through environment.

`PhotoDetailView` receives peer photos for paging. Diary landing sections
receive slices of their parent's live queries. Image Playground and entity
annotation modifiers adapt explicitly supplied recipe context to system APIs.
These inputs do not justify a second live graph or another collection query.

### Unresolved: Raw Diagnostic Deletion

`DebugContentView` directly deletes arbitrary inspected models, including
structural rows, outside product Operations and follow-up. The debug
preference also exposes it in Release builds. Choosing between unrestricted
diagnostic deletion and product-safe deletion changes data-policy behavior;
that choice remains open. Product deletion flows continue to use shared
Operations through Recipe, Diary, Photo, Tag, and Settings action services.

## Structural and Workflow Conformance

- App entry, product features, platform glue, and reusable target-local UI
  remain in `Cookle/Sources/App`, `Features`, `Platform`, and `SharedUI`.
- `CookleLibrary/Sources` and `Tests/Default` remain capability-oriented.
  No app, Widgets, or Watch unit-test target is introduced.
- The main app consumes MHPlatform and MHUI; CookleLibrary consumes
  MHPlatformCore. Widgets and Watch stay outside app-runtime and presentation
  umbrella dependencies. Release tooling remains isolated in `Tools/Release`.
- Repository checks retain package-consumer, Operations, model-directory,
  test-posture, remote-configuration, and vocabulary boundaries alongside
  SwiftLint. Xcode-native verification remains the first choice under
  `AGENTS.md`; official Apple tooling is the fallback for an observed
  integration failure, without creating another verification wrapper.

## Documentation Correction

The former April audit omitted newer Operations and live-read boundaries and
referenced a superseded verification integration. This review updates it and adds
the live-read rules and their diagnostic boundary to the existing guide and
agent contract. No schema, archive format, route vocabulary, companion
protocol, package API, or product layout change is required for this cleanup.
