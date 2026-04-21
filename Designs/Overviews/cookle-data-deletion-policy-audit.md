# Cookle Data Deletion Policy Audit

Current as of April 21, 2026.

## Purpose

This note audits how persisted Cookle data is deleted today, which deletions are
explicit versus indirect, and whether the repository follows a consistent
policy across model types.

Evidence labels used throughout this document:

- `[runtime confirmed]`: confirmed by repository tests, including
  `CookleLibrary/Tests/DeletionPolicyAuditTests.swift`
- `[source confirmed]`: confirmed directly from model, service, UI, intent, or
  migration source
- `[source-based inference]`: inferred from source shape where SwiftData macro
  behavior is not fully visible in code

Representative evidence:

- `CookleLibrary/Sources/Recipe/RecipeService.swift`
- `CookleLibrary/Sources/Recipe/RecipeFormService.swift`
- `CookleLibrary/Sources/Diary/DiaryService.swift`
- `CookleLibrary/Sources/Tag/TagService.swift`
- `CookleLibrary/Sources/Common/DataResetService.swift`
- `CookleLibrary/Sources/Common/DatabaseMigrator.swift`
- `Cookle/Sources/Debug/Views/DebugContentView.swift`
- `CookleLibrary/Tests/DeletionPolicyAuditTests.swift`
- `CookleLibrary/Tests/RecipePhotoRemovalTests.swift`

## 1) Model-by-Model Deletion Inventory

### Recipe

- Role: aggregate root for recipe content. `[source confirmed]`
- Explicit delete entrypoints:
  `RecipeService.deleteWithOutcome`, `DeleteRecipeButton`,
  `DeleteRecipeIntent`, `DebugContentView`, `DataResetService.deleteAll`.
  `[source confirmed]`
- Cascade source: none for deleting `Recipe` itself. Deleting a `Recipe`
  cascades to `PhotoObject`, `IngredientObject`, and `DiaryObject` through
  `Recipe.photoObjects`, `Recipe.ingredientObjects`, and
  `Recipe.diaryObjects`. `[source confirmed]`
- Automatic cleanup: none. `[source confirmed]`
- Reset / migration path: deleted by `DataResetService.deleteAll`; no schema
  migration stage deletes individual `Recipe` rows because
  `CookleMigrationPlan.stages` is empty. Legacy migration only relocates or
  removes whole store files. `[source confirmed]`
- Orphan allowance: not applicable as a root record. Deleting a `Recipe`
  currently leaves orphaned shared `Photo` and `Ingredient` records behind.
  `[runtime confirmed]`
- Coverage: `RecipeServiceTests`, `DeletionPolicyAuditTests`. `[runtime confirmed]`

### Diary

- Role: aggregate root for one day of diary content. `[source confirmed]`
- Explicit delete entrypoints:
  `DiaryService.deleteWithOutcome`, `DeleteDiaryButton`, `DeleteDiaryIntent`,
  `DebugContentView`, `DataResetService.deleteAll`. `[source confirmed]`
- Cascade source: none for deleting `Diary` itself. Deleting a `Diary`
  cascades to `DiaryObject` through `Diary.objects`. `[source confirmed]`
- Automatic cleanup: none. `[source confirmed]`
- Reset / migration path: deleted by `DataResetService.deleteAll`; migration
  cleanup only removes whole legacy store files. `[source confirmed]`
- Orphan allowance: not applicable as a root record. `Diary` survives
  `Recipe` deletion while its `DiaryObject` rows are removed. `[runtime confirmed]`
- Coverage: `DiaryServiceQueryTests`, `DeletionPolicyAuditTests`.
  `[runtime confirmed]`

### Photo

- Role: shared asset record reused across recipe photo rows. `[source confirmed]`
- Explicit delete entrypoints: `DebugContentView`, `DataResetService.deleteAll`,
  and direct `context.delete(photo)` inside
  `RecipeService.removePhotoWithOutcome` when the last persisted reference is
  removed. `[source confirmed]`
- Cascade source: not cascade-deleted by another model. Deleting a `Photo`
  cascades to `PhotoObject` through `Photo.objects`. `[source confirmed]`
- Automatic cleanup: removing a photo from a recipe through
  `RecipeService.removePhotoWithOutcome` deletes the `Photo` asset when
  `removedPhoto.objects.orEmpty.count == 1`. `[source confirmed]`
- Reset / migration path: deleted by `DataResetService.deleteAll`; migration
  cleanup only removes whole legacy store files. `[source confirmed]`
- Orphan allowance: mixed. `RecipeService.removePhotoWithOutcome` does not allow
  a last-referenced asset to survive, but `RecipeService.delete` leaves unique
  `Photo` rows behind, and `RecipeFormService.update` leaves removed `Photo`
  rows with no `recipes` but still pinned by detached `PhotoObject` rows.
  `[runtime confirmed]`
- Coverage: `RecipePhotoRemovalTests`, `DeletionPolicyAuditTests`.
  `[runtime confirmed]`

### Category

- Role: shared tag record for classification and filtering. `[source confirmed]`
- Explicit delete entrypoints:
  `TagService.deleteWithOutcome(context:category:)`, `DeleteTagButton`,
  `DeleteCategoryIntent`, `DebugContentView`, `DataResetService.deleteAll`.
  `[source confirmed]`
- Cascade source: none declared in source. In-use deletion detaches the
  relationship and keeps the `Recipe` alive. `[runtime confirmed]`
- Automatic cleanup: none. `[source confirmed]`
- Reset / migration path: deleted by `DataResetService.deleteAll`; migration
  cleanup only removes whole legacy store files. `[source confirmed]`
- Orphan allowance: yes. Unused `Category` records can exist until they are
  explicitly deleted. Deleting an in-use `Category` is allowed and removes the
  shared record without deleting the `Recipe`. `[runtime confirmed]`
- Coverage: `TagServiceTests`, `DeletionPolicyAuditTests`. `[runtime confirmed]`

### Ingredient

- Role: shared tag record reused by ingredient rows. `[source confirmed]`
- Explicit delete entrypoints:
  `TagService.deleteWithOutcome(context:ingredient:)`, `DeleteTagButton`,
  `DeleteIngredientIntent`, `DebugContentView`, `DataResetService.deleteAll`.
  `[source confirmed]`
- Cascade source: not cascade-deleted by another model. Deleting an
  `Ingredient` cascades to `IngredientObject` through `Ingredient.objects`.
  `[source confirmed]`
- Automatic cleanup: none. `[source confirmed]`
- Reset / migration path: deleted by `DataResetService.deleteAll`; migration
  cleanup only removes whole legacy store files. `[source confirmed]`
- Orphan allowance: yes. `TagService.delete` refuses to delete an in-use
  `Ingredient`, but `RecipeService.delete` leaves unused `Ingredient` records
  behind, and `RecipeFormService.update` leaves removed `Ingredient` rows with
  no `recipes` but still pinned by detached `IngredientObject` rows.
  `[runtime confirmed]`
- Coverage: `TagServiceTests`, `DeletionPolicyAuditTests`. `[runtime confirmed]`

### DiaryObject

- Role: parent-owned subobject that places a `Recipe` into a `Diary` section.
  `[source confirmed]`
- Explicit delete entrypoints: no user-facing root delete flow. Removed
  indirectly by `Diary` deletion, `Recipe` deletion, `DataResetService.deleteAll`,
  and `DebugContentView`. `[source confirmed]`
- Cascade source: deleting a `Diary` cascades through `Diary.objects`; deleting
  a `Recipe` cascades through `Recipe.diaryObjects`. `[source confirmed]`
- Automatic cleanup: none for replaced rows during `DiaryService.update`.
  Updating a saved `Diary` leaves the previous `DiaryObject` persisted with
  `diary == nil`. `[runtime confirmed]`
- Reset / migration path: deleted by `DataResetService.deleteAll`; migration
  cleanup only removes whole legacy store files. `[source confirmed]`
- Orphan allowance: mixed. Root deletion removes `DiaryObject` rows, but update
  flows currently allow detached orphan rows. `[runtime confirmed]`
- Coverage: `DeletionPolicyAuditTests`. `[runtime confirmed]`

### PhotoObject

- Role: parent-owned subobject that keeps photo order and the link to `Photo`.
  `[source confirmed]`
- Explicit delete entrypoints: no user-facing root delete flow. Removed
  indirectly by `Recipe` deletion, `RecipeService.removePhotoWithOutcome`,
  `DataResetService.deleteAll`, and `DebugContentView`. `[source confirmed]`
- Cascade source: deleting a `Recipe` cascades through `Recipe.photoObjects`;
  deleting a `Photo` cascades through `Photo.objects`. `[source confirmed]`
- Automatic cleanup: none for replaced rows during `RecipeFormService.update`.
  Updating a saved `Recipe` leaves the previous `PhotoObject` persisted with
  `recipe == nil`. `[runtime confirmed]`
- Reset / migration path: deleted by `DataResetService.deleteAll`; migration
  cleanup only removes whole legacy store files. `[source confirmed]`
- Orphan allowance: mixed. Root deletion removes `PhotoObject` rows, but update
  flows currently allow detached orphan rows. Those rows keep removed `Photo`
  assets alive through `Photo.objects`. `[runtime confirmed]`
- Coverage: `RecipePhotoRemovalTests`, `DeletionPolicyAuditTests`.
  `[runtime confirmed]`

### IngredientObject

- Role: parent-owned subobject that keeps ingredient order, amount text, and
  the link to `Ingredient`. `[source confirmed]`
- Explicit delete entrypoints: no user-facing root delete flow. Removed
  indirectly by `Recipe` deletion, `DataResetService.deleteAll`, and
  `DebugContentView`. `[source confirmed]`
- Cascade source: deleting a `Recipe` cascades through `Recipe.ingredientObjects`;
  deleting an `Ingredient` cascades through `Ingredient.objects`.
  `[source confirmed]`
- Automatic cleanup: none for replaced rows during `RecipeFormService.update`.
  Updating a saved `Recipe` leaves the previous `IngredientObject` persisted
  with `recipe == nil`. `[runtime confirmed]`
- Reset / migration path: deleted by `DataResetService.deleteAll`; migration
  cleanup only removes whole legacy store files. `[source confirmed]`
- Orphan allowance: mixed. Root deletion removes `IngredientObject` rows, but
  update flows currently allow detached orphan rows. Those rows keep removed
  `Ingredient` records alive through `Ingredient.objects`. `[runtime confirmed]`
- Coverage: `DeletionPolicyAuditTests`. `[runtime confirmed]`

## 2) Deletion Trigger Classification

### Explicit user deletion

- `Recipe`: explicit delete from detail UI, list UI, and App Intent.
  `[source confirmed]`
- `Diary`: explicit delete from detail UI and App Intent. `[source confirmed]`
- `Category`: explicit delete from tag UI and App Intent, even when in use.
  `[runtime confirmed]`
- `Ingredient`: explicit delete from tag UI and App Intent, but denied while
  any `Recipe` still references it. `[runtime confirmed]`

### Explicit full deletion or maintenance deletion

- `DataResetService.deleteAll` deletes all eight persisted model types when run
  against saved data. `[runtime confirmed]`
- `DatabaseMigrator.removeLegacyStoreFilesIfNeeded` removes legacy store files
  after relocation validation. This is store-file cleanup, not per-row record
  cleanup. `[source confirmed]`

### Debug or developer deletion

- `DebugContentView` exposes direct raw deletion through
  `models[index].delete()`, bypassing service-layer policy guards.
  `[source confirmed]`

### App-driven cleanup

- `RecipeService.removePhotoWithOutcome` deletes the `PhotoObject` row and also
  deletes the `Photo` asset when the removed photo has exactly one persisted
  object reference. `[runtime confirmed]`
- No matching app-driven cleanup exists for `Ingredient`, `Category`, or any of
  the update flows that replace child rows. `[source confirmed]`

## 3) Type Comparison Review

- `Photo` is the most policy-complex shared record. It is treated as a
  recipe-linked gallery asset in product copy and browse UI, but its deletion
  semantics are surface-dependent. `[source confirmed]`
- `Category` and `Ingredient` are both shared tags, but they follow different
  delete rules. `Category` can be deleted while in use and the `Recipe`
  survives; `Ingredient` cannot be deleted while in use. `[runtime confirmed]`
- `DiaryObject`, `PhotoObject`, and `IngredientObject` look like parent-owned
  rows by model design, and root deletions treat them that way. `[source confirmed]`
- The same three subobject types are not consistently parent-owned in update
  flows. Replacing parent collections leaves detached rows behind instead of
  deleting them. `[runtime confirmed]`
- `PhotoObject` and `IngredientObject` are especially important because their
  detached rows keep old shared records alive through inverse relationships.
  That means a recipe update can create both a detached row and a retained
  asset or tag record in one step. `[runtime confirmed]`

## 4) Orphan Policy Assessment

- Cookle does not currently enforce a repository-wide "no orphan data" policy.
  `[runtime confirmed]`
- Parent root deletion behaves mostly as expected:
  `Recipe` deletion removes `PhotoObject`, `IngredientObject`, and `DiaryObject`
  rows; `Diary` deletion removes `DiaryObject` rows. `[runtime confirmed]`
- Shared records are not treated consistently:
  `Ingredient` orphans are allowed, `Category` in-use delete is allowed, and
  `Photo` orphan cleanup is enforced only in `removePhotoWithOutcome`.
  `[runtime confirmed]`
- Update flows are the clearest consistency gap. Replacing recipe photos,
  recipe ingredients, or diary rows leaves detached subobjects behind instead
  of deleting them. `[runtime confirmed]`
- Because detached `PhotoObject` and `IngredientObject` rows remain persisted,
  the repository can retain records that are no longer reachable from any
  `Recipe` while still appearing "referenced" through subobject inverses.
  `[runtime confirmed]`

## 5) Inconsistencies and Policy Gaps

- `Photo` deletion policy depends on surface:
  removing one photo from a recipe can delete the last asset, but deleting the
  whole recipe keeps the same asset. `[runtime confirmed]`
- `Category` and `Ingredient` use different in-use delete rules without an
  explicit product rationale recorded in code comments or decision documents.
  `[source confirmed]`
- Parent-owned subobjects are only reliably non-orphaned on root deletion, not
  on update. This undermines the apparent ownership model in
  `Recipe.photoObjects`, `Recipe.ingredientObjects`, and `Diary.objects`.
  `[runtime confirmed]`
- `DebugContentView` bypasses all service-layer deletion rules, so it can
  produce states that normal user flows would block. `[source confirmed]`
- Store migration cleanup is coarse-grained file cleanup rather than typed row
  cleanup. That is acceptable, but it should not be confused with a model-level
  deletion policy. `[source confirmed]`

## 6) Recommended Deletion Policy

### Working Principle

- While Cookle is still small and the long-term data model is not yet fully
  settled, non-Object persisted data should be deleted conservatively.
  User-important records should not disappear just because the current model
  shape happens to make them look unused.
- `DiaryObject`, `PhotoObject`, and `IngredientObject` are explanatory
  parent-owned rows. They are not durable user-owned records in their own
  right, so losing the parent should also remove the row.
- Prefer unlink over delete for non-Object persisted records.
  Detaching a relation is safer than deleting a record when the product meaning
  of that record is still evolving.
- Keep `Delete All` and debug raw deletion as explicit exception paths.
- Treat ordinary root-model delete flows as case-by-case exceptions.
  A delete surface can remain if it was deliberately designed and its product
  meaning is clear, but ad-hoc or accidental delete behavior should be removed.

### Desired Steady-State Policy by Type

- `DiaryObject`, `PhotoObject`, `IngredientObject`:
  parent-owned rows; they should never persist detached. `[runtime confirmed]`
- `Photo`, `Category`, `Ingredient`:
  shared non-Object records; default to keep, even when a link is removed,
  unless an explicit and clearly intentional delete flow says otherwise.
- `Recipe`, `Diary`:
  root records; do not assume they must be removed or preserved globally.
  Evaluate each existing delete surface by whether it is clearly intentional and
  product-legible.
- `Delete All` and debug raw delete:
  keep as exception mechanisms rather than using them as evidence of ordinary
  product policy.

### Recommended Implementation Order

- First, fix detached Object cleanup:
  `RecipeFormService.updateWithOutcome` should remove replaced `PhotoObject` and
  `IngredientObject`, and `DiaryService.updateWithOutcome` should remove
  replaced `DiaryObject`. This is the clearest current consistency defect.
- Second, stop implicit `Photo` asset deletion in
  `RecipeService.removePhotoWithOutcome` and make the operation unlink-only by
  default.
- Third, re-evaluate ordinary delete surfaces for `Recipe` and `Diary`.
  Keep them only if they are judged to be deliberate, explicit product actions
  rather than incidental convenience paths.
- Fourth, re-evaluate the current `Category` and `Ingredient` split and either
  justify it explicitly or simplify it.
- Fifth, keep the current audit tests as observation coverage until each policy
  change lands, then flip only the expectations that intentionally changed.

### Recommendation

- Recommend a conservative deletion posture for all non-Object persisted models.
  Under the current product phase, it is safer to preserve `Photo`, `Category`,
  `Ingredient`, and possibly `Recipe` / `Diary` than to let them disappear
  through implicit cleanup. `[runtime confirmed]`
- Recommend aggressive cleanup only for Object types.
  Detached `DiaryObject`, `PhotoObject`, and `IngredientObject` rows should be
  treated as invalid persisted state rather than tolerated leftovers.
  `[runtime confirmed]`
- Recommend documenting ordinary delete surfaces separately from storage cleanup.
  This keeps "the user explicitly deleted something" distinct from "the app
  silently cleaned up a record because a relationship changed."
