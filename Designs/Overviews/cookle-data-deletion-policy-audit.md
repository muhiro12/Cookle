# Cookle Data Deletion Policy Audit

Current as of April 21, 2026.

## Purpose

This note records how persisted Cookle data is deleted after the conservative
deletion-policy refactor. It also acts as the source of truth for future
deletion work, so it distinguishes between current implementation facts and the
forward design policy.

The current working rule is:

- keep non-Object persisted records conservatively
- delete parent-owned Object rows when they lose their parent
- prefer unlink over delete
- treat `Delete All` and debug raw deletion as explicit exception paths

Evidence labels used below:

- `[runtime confirmed]`: confirmed by repository tests
- `[source confirmed]`: confirmed directly from models, services, UI, intents,
  or container/bootstrap code
- `[source-based inference]`: inferred from source shape where SwiftData macro
  behavior is not fully visible in code

Representative evidence:

- `CookleLibrary/Sources/Recipe/RecipeService.swift`
- `CookleLibrary/Sources/Recipe/RecipeFormService.swift`
- `CookleLibrary/Sources/Diary/DiaryService.swift`
- `CookleLibrary/Sources/Common/DetachedObjectCleanupService.swift`
- `CookleLibrary/Sources/Common/ModelContainerFactory.swift`
- `Cookle/Sources/Photo/Views/PhotoListView.swift`
- `Cookle/Sources/Tag/Intents/DeleteCategoryIntent.swift`
- `Cookle/Sources/Tag/Intents/DeleteIngredientIntent.swift`
- `CookleLibrary/Tests/DeletionPolicyAuditRootModelTests.swift`
- `CookleLibrary/Tests/DeletionPolicyAuditObjectLifecycleTests.swift`
- `CookleLibrary/Tests/DetachedObjectCleanupServiceTests.swift`
- `CookleLibrary/Tests/RecipePhotoRemovalTests.swift`

## 1) Model-by-Model Deletion Inventory

### Recipe

- Role: aggregate root for recipe content. `[source confirmed]`
- Explicit delete entrypoints:
  `RecipeService.deleteWithOutcome`, `DeleteRecipeButton`,
  `DeleteRecipeIntent`, `DebugContentView`, `DataResetService.deleteAll`.
  `[source confirmed]`
- Cascade source: deleting a `Recipe` cascades to `PhotoObject`,
  `IngredientObject`, and `DiaryObject` through `Recipe.photoObjects`,
  `Recipe.ingredientObjects`, and `Recipe.diaryObjects`. `[source confirmed]`
- Automatic cleanup: none for the `Recipe` row itself. `[source confirmed]`
- Reset / migration / maintenance path:
  deleted by `DataResetService.deleteAll`; no schema migration stage deletes
  individual `Recipe` rows because `CookleMigrationPlan.stages` is empty.
  `[source confirmed]`
- Orphan allowance: not applicable as a root record. Deleting a `Recipe`
  keeps shared `Photo`, `Ingredient`, and `Category` records. `[runtime confirmed]`
- Coverage:
  `RecipeServiceTests`, `DeletionPolicyAuditRootModelTests`.
  `[runtime confirmed]`

### Diary

- Role: aggregate root for one day of diary content. `[source confirmed]`
- Explicit delete entrypoints:
  `DiaryService.deleteWithOutcome`, `DeleteDiaryButton`, `DeleteDiaryIntent`,
  `DebugContentView`, `DataResetService.deleteAll`. `[source confirmed]`
- Cascade source: deleting a `Diary` cascades to `DiaryObject` through
  `Diary.objects`. `[source confirmed]`
- Automatic cleanup: none for the `Diary` row itself. `[source confirmed]`
- Reset / migration / maintenance path:
  deleted by `DataResetService.deleteAll`; schema migration still has no row
  deletion stage. `[source confirmed]`
- Orphan allowance: not applicable as a root record. `Diary` survives
  unrelated `Recipe` deletion while its owned `DiaryObject` rows are removed.
  `[runtime confirmed]`
- Coverage:
  `DiaryServiceQueryTests`, `DeletionPolicyAuditRootModelTests`.
  `[runtime confirmed]`

### Photo

- Role: shared asset record reused across recipe photo rows and now shown in
  the photo gallery even when unlinked. `[source confirmed]`
- Explicit delete entrypoints:
  `PhotoView`, `DebugContentView`, and `DataResetService.deleteAll`. Ordinary
  recipe photo removal remains unlink-only, while photo detail now exposes
  explicit asset delete with recipe-row impact confirmation. `[source confirmed]`
- Cascade source: deleting a `Photo` cascades to `PhotoObject` through
  `Photo.objects`. `[source confirmed]`
- Automatic cleanup: none for the `Photo` asset itself.
  `RecipeService.removePhotoWithOutcome` is unlink-only and deletes only the
  `PhotoObject` row. `[runtime confirmed]`
- Reset / migration / maintenance path:
  deleted by `DataResetService.deleteAll`; detached-object maintenance never
  deletes `Photo` roots. `[source confirmed]`
- Orphan allowance: yes by design. A `Photo` can remain stored with no linked
  `Recipe`, and the Photos tab now surfaces those assets. `[runtime confirmed]`
- Coverage:
  `RecipePhotoRemovalTests`, `DeletionPolicyAuditObjectLifecycleTests`,
  `DetachedObjectCleanupServiceTests`. `[runtime confirmed]`

### Category

- Role: shared tag record for classification and filtering. `[source confirmed]`
- Explicit delete entrypoints:
  `TagView`, `DeleteCategoryIntent`, `DebugContentView`, and
  `DataResetService.deleteAll`. Ordinary category delete now uses recipe-impact
  confirmation in both product UI and App Intents. `[source confirmed]`
- Cascade source: none declared in source. `[source confirmed]`
- Automatic cleanup: none. `[source confirmed]`
- Reset / migration / maintenance path:
  deleted by `DataResetService.deleteAll`; detached-object maintenance never
  deletes `Category` roots. `[source confirmed]`
- Orphan allowance: yes by design. Categories remain stored even when no recipe
  currently uses them. `[source confirmed]`
- Coverage:
  `TagServiceTests`, `MutationEffectPropagationTests`. `[runtime confirmed]`

### Ingredient

- Role: shared tag record reused by ingredient rows. `[source confirmed]`
- Explicit delete entrypoints:
  `TagView`, `DeleteIngredientIntent`, `DebugContentView`, and
  `DataResetService.deleteAll`. Ordinary ingredient delete now succeeds only
  when the ingredient is unused. `[source confirmed]`
- Cascade source: deleting an `Ingredient` cascades to `IngredientObject`
  through `Ingredient.objects`. `[source confirmed]`
- Automatic cleanup: none for the `Ingredient` root itself. `[source confirmed]`
- Reset / migration / maintenance path:
  deleted by `DataResetService.deleteAll`; detached-object maintenance never
  deletes `Ingredient` roots. `[source confirmed]`
- Orphan allowance: yes by design. Ingredients remain stored even when no
  recipe currently uses them. `[runtime confirmed]`
- Coverage:
  `TagServiceTests`, `DeletionPolicyAuditObjectLifecycleTests`,
  `DetachedObjectCleanupServiceTests`. `[runtime confirmed]`

### DiaryObject

- Role: parent-owned subobject that places a `Recipe` into a `Diary` meal slot.
  `[source confirmed]`
- Explicit delete entrypoints: no user-facing root delete flow. Removed
  indirectly by `Diary` deletion, `Recipe` deletion, detached-object
  maintenance, `DataResetService.deleteAll`, and `DebugContentView`.
  `[source confirmed]`
- Cascade source: deleting a `Diary` cascades through `Diary.objects`; deleting
  a `Recipe` cascades through `Recipe.diaryObjects`. `[source confirmed]`
- Automatic cleanup:
  `DiaryService.updateWithOutcome` deletes replaced rows after rebuilding the
  owned collection. `[runtime confirmed]`
- Reset / migration / maintenance path:
  `DetachedObjectCleanupService` deletes ownerless rows one time during live
  app container preparation. `[runtime confirmed]`
- Orphan allowance: no in steady state. Update flows and one-time maintenance
  remove detached rows. `[runtime confirmed]`
- Coverage:
  `DeletionPolicyAuditObjectLifecycleTests`,
  `DetachedObjectCleanupServiceTests`. `[runtime confirmed]`

### PhotoObject

- Role: parent-owned subobject that keeps photo order and the link to `Photo`.
  `[source confirmed]`
- Explicit delete entrypoints: no user-facing root delete flow. Removed
  indirectly by `Recipe` deletion, `RecipeService.removePhotoWithOutcome`,
  detached-object maintenance, `DataResetService.deleteAll`, and
  `DebugContentView`. `[source confirmed]`
- Cascade source: deleting a `Recipe` cascades through `Recipe.photoObjects`;
  deleting a `Photo` cascades through `Photo.objects`. `[source confirmed]`
- Automatic cleanup:
  `RecipeFormService.updateWithOutcome` deletes replaced rows after rebuilding
  the owned collection. `[runtime confirmed]`
- Reset / migration / maintenance path:
  `DetachedObjectCleanupService` deletes ownerless rows one time during live
  app container preparation. `[runtime confirmed]`
- Orphan allowance: no in steady state. Detached rows are no longer tolerated
  after update flows or maintenance. `[runtime confirmed]`
- Coverage:
  `RecipePhotoRemovalTests`, `DeletionPolicyAuditObjectLifecycleTests`,
  `DetachedObjectCleanupServiceTests`. `[runtime confirmed]`

### IngredientObject

- Role: parent-owned subobject that keeps ingredient order, amount text, and
  the link to `Ingredient`. `[source confirmed]`
- Explicit delete entrypoints: no user-facing root delete flow. Removed
  indirectly by `Recipe` deletion, detached-object maintenance,
  `DataResetService.deleteAll`, and `DebugContentView`. `[source confirmed]`
- Cascade source: deleting a `Recipe` cascades through
  `Recipe.ingredientObjects`; deleting an `Ingredient` cascades through
  `Ingredient.objects`. `[source confirmed]`
- Automatic cleanup:
  `RecipeFormService.updateWithOutcome` deletes replaced rows after rebuilding
  the owned collection. `[runtime confirmed]`
- Reset / migration / maintenance path:
  `DetachedObjectCleanupService` deletes ownerless rows one time during live
  app container preparation. `[runtime confirmed]`
- Orphan allowance: no in steady state. Detached rows are no longer tolerated
  after update flows or maintenance. `[runtime confirmed]`
- Coverage:
  `DeletionPolicyAuditObjectLifecycleTests`,
  `DetachedObjectCleanupServiceTests`. `[runtime confirmed]`

## 2) Deletion Trigger Classification

### Explicit user deletion

- `Recipe`: explicit delete from detail UI, list UI, and App Intent.
  `[source confirmed]`
- `Diary`: explicit delete from detail UI and App Intent. `[source confirmed]`
- No ordinary user-facing delete remains for `Photo`, `Category`, or
  `Ingredient`. `[source confirmed]`

### Explicit full deletion or maintenance deletion

- `DataResetService.deleteAll` deletes all eight persisted model types when run
  against saved data. `[runtime confirmed]`
- `DatabaseMigrator.removeLegacyStoreFilesIfNeeded` removes whole legacy store
  files after relocation validation. This is store-file cleanup, not typed row
  cleanup. `[source confirmed]`
- `DetachedObjectCleanupService.runIfNeeded` deletes ownerless
  `DiaryObject`, `PhotoObject`, and `IngredientObject` rows one time during
  live app container preparation. `[runtime confirmed]`

### Debug or developer deletion

- `DebugContentView` exposes direct raw deletion through
  `models[index].delete()`, bypassing service-layer policy guards.
  `[source confirmed]`

### App-driven cleanup

- `RecipeFormService.updateWithOutcome` deletes replaced `PhotoObject` and
  `IngredientObject` rows after rebuilding the new owned collections.
  `[runtime confirmed]`
- `DiaryService.updateWithOutcome` deletes replaced `DiaryObject` rows after
  rebuilding the new owned collection. `[runtime confirmed]`
- `RecipeService.removePhotoWithOutcome` deletes the `PhotoObject` row and
  unlinks the `Photo` asset, but it no longer deletes the asset itself.
  `[runtime confirmed]`

## 3) Type Comparison Review

- `Photo` is now a conservative shared asset. It remains stored after unlink,
  and the Photos tab presents all stored assets instead of only
  recipe-linked assets. `[runtime confirmed]`
- `Category` and `Ingredient` are both shared tags, but their current delete
  policy differs. `Category` now has ordinary explicit delete with
  recipe-impact confirmation, while `Ingredient` still has no ordinary delete
  surface. `[source confirmed]`
- `DiaryObject`, `PhotoObject`, and `IngredientObject` are now consistently
  parent-owned rows. Root deletion, update flows, and one-time maintenance all
  treat them as disposable when detached. `[runtime confirmed]`
- `Recipe` and `Diary` remain the only ordinary delete exceptions in the main
  product surface. `[source confirmed]`

## 4) Orphan Policy Assessment

- Cookle does not enforce a global "no orphan data" rule across every model.
  Instead, it now uses an explicit split policy. `[runtime confirmed]`
- Shared and root records are preserved conservatively:
  `Photo`, `Category`, `Ingredient`, and shared records behind deleted or
  updated parents are allowed to remain stored. `[runtime confirmed]`
- Parent-owned Object rows are not allowed to remain detached in the intended
  steady state. Update flows delete replaced rows, and one-time maintenance
  clears legacy detached rows. `[runtime confirmed]`
- Root deletion still removes owned child rows through cascade, while shared
  roots remain stored. `[runtime confirmed]`

## 5) Current Implementation Gaps Against the Forward Policy

- Detached-object maintenance runs only from live app container preparation.
  Preview and in-memory test containers do not invoke it automatically unless a
  test calls the service directly. `[source confirmed]`
- `DebugContentView` still bypasses all ordinary policy checks and can delete
  any persisted model directly. That remains an intentional maintenance
  exception. `[source confirmed]`

## 6) Forward Deletion Design Policy

This section is the source of truth for future delete-related product and
implementation work.

- `Recipe` and `Diary` may continue to expose ordinary explicit delete because
  they are user-authored root records.
- `Recipe` delete should disclose its cross-model impact. The confirmation flow
  should explain how many diary meal rows will be removed when the recipe is
  deleted.
- `Diary` delete should remain a self-contained delete flow. Its confirmation
  should describe removal of the diary and its owned `DiaryObject` rows without
  implying deletion of other root records.
- `Photo` must keep unlink and asset delete as separate actions. Removing a
  photo from a recipe should stay unlink-only, while explicit asset delete
  should disclose how many recipe photo rows will be affected.
- `Category` may expose ordinary explicit delete, but the confirmation flow
  should disclose how many recipes will lose that category relation.
- `Ingredient` should only be deletable when unused. If any recipe still
  references the ingredient, ordinary delete should be rejected because the
  delete would remove recipe ingredient rows and their amount text.
- `DiaryObject`, `PhotoObject`, and `IngredientObject` are parent-owned rows.
  They should not gain ordinary standalone delete surfaces and should continue
  to be removed only by parent mutation, parent deletion, cascade, or explicit
  maintenance cleanup.
- Prefer unlink over delete when mutating shared or reusable persisted records.
- Keep `Delete All` and debug raw delete as explicit maintenance exceptions,
  not as ordinary product policy.
