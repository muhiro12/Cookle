# Cookle Mutation Semantics

Current behavior as of September 28, 2026.

## Purpose

This note records what Cookle's rename, merge, delete, and edit paths actually
do today, so that impact review, stale-data handling, and recovery work can be
designed against stated semantics rather than re-read from source each time.

It is a description of current behavior, not a proposal. Where a behavior looks
like an open question rather than a settled rule, it is marked **Open** and left
for the owning issue to decide.

Deletion is covered here only where it interacts with rename, merge, or edit.
The July 2026 model-by-model deletion inventory remains in
[the deletion policy audit](cookle-data-deletion-policy-audit.md), and the
storage contracts it was superseded by are in
[ADR 0011](../Decisions/0011-preserve-swiftdata-storage-contracts.md).

Evidence labels:

- `[runtime confirmed]`: asserted by a named repository test
- `[source confirmed]`: read directly from models, services, or operations

Primary sources:

- `CookleLibrary/Sources/Tag/TagService.swift`
- `CookleLibrary/Sources/Tag/TagOperations.swift`
- `CookleLibrary/Sources/Recipe/RecipeFormService.swift`
- `CookleLibrary/Sources/Recipe/RecipeService.swift`
- `CookleLibrary/Sources/Diary/DiaryService.swift`
- `CookleLibrary/Sources/Persistence/CascadeDeletionSupport.swift`
- `CookleLibrary/Sources/Persistence/DeduplicatedModelCreation.swift`

## 1) Two different notions of "the same value"

Cookle compares tag values two ways, and they do not agree.

**Creation reuse — exact equality.** `Ingredient.create` and `Category.create`
go through `DeduplicatedModelCreation.resolve`, whose lookup is
`.valueIs(value)`: a byte-exact match on the stored string. Saving a recipe that
names `sugar` when `Sugar` already exists therefore creates a **second**
record. `[runtime confirmed]` — `ingredient_create_reuses_existing_value`,
`category_create_reuses_existing_value`.

**Duplicate detection — normalized equality.** `TagService.duplicateKey` trims
the value, collapses internal whitespace runs to a single space, and applies
`folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
locale: .current)`. `Sugar`, `sugar`, `ｓｕｇａｒ`, `sugár`, and `  sugar  `
all land in one group. `[runtime confirmed]` —
`duplicateTags_matches_case_width_diacritic_and_spacing_variants`,
`duplicateTags_keeps_distinct_values_separate`.

The consequence is deliberate in shape and worth stating plainly: **Cookle
never merges on its own, it only offers to.** Creation stays conservative so a
save cannot silently fold a user's distinct label into an existing one, and
detection stays generous so the merge affordance can find what a user would
call a duplicate.

Two properties follow that callers need to know:

- The grouping key is **locale-sensitive** (`locale: .current`). The same pair
  of values can group on one device and not on another.
- A rename is not checked against either notion, so renaming a tag onto an
  existing value is a supported way to *produce* a duplicate group.

## 2) Ingredient and Category

### Rename

`TagService.renameWithOutcome` trims whitespace and newlines, rejects an empty
result with `TagOperationsError.emptyValue`, and assigns the value.
`[runtime confirmed]` — `rename_updates_ingredient_value`,
`rename_updates_category_value`.

The row keeps its identity. Every `IngredientObject`, every recipe relation, and
every past diary that reaches the tag therefore shows the **new** label
immediately; nothing captures the old one. `[source confirmed]`

No uniqueness check runs. Renaming onto an existing value leaves two records
that duplicate detection will group. `[source confirmed]`

### Delete

`Ingredient` deletion is **guarded**: `deleteWithOutcome(ingredient:)` throws
`TagOperationsError.ingredientInUse(value)` unless `ingredient.recipes` is
empty, so only an unused ingredient can be removed.
`[runtime confirmed]` — `delete_unused_ingredient_removes_only_the_root_record`,
`delete_in_use_ingredient_is_rejected`.

`Category` deletion is **not** guarded. `Category.recipes` is the inverse of
`Recipe.categories`, which carries the default nullify rule, so deleting a
category detaches it from every recipe and leaves the recipes intact.
`[runtime confirmed]` — `delete_category_removes_recipe_relation_but_keeps_recipe`.

Both paths publish `.notificationPlanChanged`. `[source confirmed]`

### Merge

`mergeDuplicatesWithOutcome(keeping:)` fetches all tags of that kind, takes the
duplicate group of the supplied tag, and drops the kept tag from the children.
Anything not in the group is untouched, and merging a group that no longer has
duplicates is a no-op. `[runtime confirmed]` —
`mergeDuplicates_is_a_no_op_once_the_duplicates_are_gone`,
`mergeDuplicates_tolerates_a_duplicate_that_was_already_deleted`.

**Ingredient merge** re-points each child's `IngredientObject` rows at the kept
ingredient with `object.update(ingredient: parent, amount: object.amount, order:
object.order)` — the amount text and the display order are carried across
explicitly — then calls `recipe.refreshIngredients()` on each affected
recipe to rebuild its flattened relation, then deletes the children.
Because the rows are re-pointed *before* the delete, the child's cascade no
longer owns them.
`[runtime confirmed]` —
`mergeDuplicateIngredients_reassignsIngredientObjectsAndDeletesChildren`,
`mergeDuplicateIngredients_preserves_amounts_and_row_order`.

**Category merge** rewrites each affected recipe's category list: child
categories are filtered out, and the kept category is appended if it was not
already present. `[runtime confirmed]` —
`mergeDuplicateCategories_reassignsRecipesAndDeletesChildren`.

**Open.** Because the kept category is *appended*, a recipe that carried only a
child category ends up with the survivor at the end of its list rather than in
the position the child held. Categories have no user-visible ordering today, so
this has no effect now; it would if ordering were ever surfaced.

## 3) Recipe edit

`RecipeFormService.makeDraft` validates before anything is written:

- an empty name throws `RecipeFormValidationError.emptyName`
- serving size and cooking time accept full-width digits via
  `.fullwidthToHalfwidth`; empty becomes `0`; anything else throws
  `invalidServingSize` / `invalidCookingTime`
- ingredient rows with an empty name, empty steps, and empty category values are
  dropped, and the surviving rows keep their relative order

`[runtime confirmed]` — `makeDraft_converts_fullwidth_numbers`,
`makeDraft_removes_empty_rows_but_preserves_order`,
`makeDraft_throws_validation_error_for_invalid_values`.

### Ordered child rows are replaced, not mutated

`updateWithOutcome` captures the existing `photoObjects` and
`ingredientObjects`, builds an entirely **new** row for every entry in the draft
with `order = index + 1`, assigns the new set through `recipe.update(content:)`,
and only then deletes the previous rows. `[source confirmed]`

So, for any edit that saves:

- `IngredientObject` and `PhotoObject` **identity does not survive**. Anything
  holding one of those rows across a save is holding a deleted object.
- The shared `Ingredient`, `Category`, and `Photo` records **do** survive, and
  are reused when their key matches — value equality for tags, image data
  equality for photos. `[runtime confirmed]` —
  `preview_style_recipe_creation_reuses_existing_tags`,
  `create_reusesExistingBinaryData`.
- `order` is re-derived from array position on every save, so it is always
  1-based and dense.
- `modifiedTimestamp` is refreshed; `createdTimestamp` is not.

`[runtime confirmed]` — `create_and_update_keep_order_and_refresh_modified_timestamp`,
`update_rebuilds_photos_in_draft_order`.

### Removing one photo

`RecipeService.removePhotoWithOutcome` is the exception to the rule above: it
deletes the single `PhotoObject` and re-applies the remaining rows as they are.

- The shared `Photo` asset is **never** deleted, only unlinked, whether or not
  anything else still references it. `RecipePhotoRemovalBehavior`
  currently ignores both of its count arguments and always returns
  `.removeFromRecipe`. `[runtime confirmed]` —
  `removePhotoWithOutcome_keepsSharedPhotoAssetWhenAnotherReferenceExists`,
  `removePhotoWithOutcome_keepsPhotoAssetWhenItBecomesUnlinked`.
- The surviving rows keep their original `order` values, so this path leaves a
  **gap** in the sequence. A later full edit renumbers them.
  `[source confirmed]`

**Open.** Unlinked `Photo` rows are never collected. That is the conservative
choice ADR 0011 asks for, but nothing currently reports how many accumulate.

## 4) Linked Diary history

A `DiaryObject` holds a live `@Relationship` to a `Recipe`, and no recipe edit
path touches `recipe.diaries` or `recipe.diaryObjects`. `[source confirmed]`

Therefore **editing a recipe retroactively changes what past diary entries
show.** A diary from six months ago displays the recipe's current name and
current content, not what was cooked that day. Cookle stores no historical
snapshot of recipe content.

Deleting a recipe behaves differently, because `Recipe.diaryObjects` carries
`deleteRule: .cascade`: the recipe's **meal rows are removed** from every diary
that referenced it, while the `Diary` entries themselves — their date and
note — survive. `[source confirmed]`

`RecipeDeleteCopy.message` states this to the user accurately, with separate
wording for zero, one, and many affected meal rows. `[source confirmed]`

**Decision for the current release.** Live reference semantics are the accepted
behavior for this release. Past diary entries keep referencing the current
recipe, and no model, schema, or export format change introduces recipe
snapshots. Immutable diary history remains the preferred long-term direction
and is feasible later; it is deferred because it needs its own schema,
migration, export, and synchronization design, not because the platform
prevents it. Tracked by https://github.com/muhiro12/Cookle/issues/132.

## 5) Diary edit and delete

`DiaryService.updateWithOutcome` uses the same replace-then-delete shape as
recipe edit: new `DiaryObject` rows per meal type with `order = index + 1`,
assigned before the previous rows are deleted. `[source confirmed]`

Moving a diary to a day that another diary already occupies throws
`DiaryDayConflictError.dayAlreadyOccupied`; keeping the same calendar day skips
the check entirely. `[source confirmed]`

`deleteWithOutcome(diary:)` cascades to the diary's meal rows through
`Diary.objects` and leaves every referenced recipe intact. `[source confirmed]`

## 6) Why deletes materialize their rows first

Every delete path that owns cascade rows calls
`CascadeDeletionSupport.materialize` before `context.delete`. This is not
bookkeeping: a row owned by two cascade relationships — which `DiaryObject`,
`IngredientObject`, and `PhotoObject` all are — makes SwiftData `fatalError`
inside `ModelContext.rollback()` if it is still a fault when its parent is
deleted. A failed save would then take the process down instead of recovering.
Reading a stored property first gives each row real backing data;
`persistentModelID`, `isDeleted`, and the description are not enough.

The reasoning and the trap text are recorded on the type itself, and the
behavior is pinned by `MutationRollbackPersistenceTests`.

## 7) Follow-up effects

Every mutation returns a `MutationOutcome` carrying the effects a caller must
publish. `[source confirmed]`

| Mutation | Effects |
| --- | --- |
| Tag rename / delete / merge | `.notificationPlanChanged` |
| Recipe create / update / delete / photo removal | `.recipeDataChanged`, `.notificationPlanChanged` |
| Diary create / update / delete | `.diaryDataChanged`, `.notificationPlanChanged` |

Diary rows are the source of each recipe's made count and last-cooked date,
which is why a diary change invalidates the scheduled suggestion plan as well.
Propagation is pinned by `OperationsMutationEffectPropagationTests`.

## 8) Reviewed deletion and tag merge

Recipe deletion and tag deletion/merge now capture a value-type impact review
through `RecipeOperations` or `TagOperations`. The app shows bounded examples
of affected diary meal rows, recipe names, and duplicate tag values alongside
the existing impact explanation. Recipe and tag deletion intents use the same
reviewed Operations contract. `[source confirmed]`

Applying a reviewed mutation re-fetches its targets and compares affected
identities and the values displayed in the review. A changed recipe name,
tag value, affected recipe name, diary date, meal type, or affected set makes
that review stale even when the count is unchanged. Unrelated changes do not
invalidate it. Missing targets produce a recoverable result without applying
the mutation. The app refreshes stale reviews and asks again; intents bound
repeated confirmation attempts. `[runtime confirmed]` for the Operations
contract — `ReviewedRecipeDeletionTests` and `ReviewedTagMutationTests`;
`[source confirmed]` for presentation and intent orchestration.

This review does not change deletion, ingredient quantity/order preservation,
or historical diary reference semantics described above. It does not provide
after-save undo or reverse writes already synchronized to another device.

**Bounded recovery.** Recovery from an applied recipe deletion, tag merge or
deletion, or recipe edit is bounded to a data file exported before the change.
Importing that file through section 9 adds a deleted recipe back, can replace
an edited or tag-merged recipe with its exported content in place, and can
combine a day's diary so meal rows removed by a recipe deletion return;
replacing the whole library returns to the exported state. Merging restores
recorded content, not previous identities: a merged-away or deleted tag returns
only as a value of the recipes that carried it, and changes made after the
export are not part of the recovery.
Standard undo is not offered for these operations because a SwiftData
`UndoManager` feasibility check did not restore a deleted recipe durably after
saving and reopening the store. With iCloud sync enabled, the original change
and a later recovery import each synchronize as ordinary saves; neither is
withdrawn from devices that already received it. `[source confirmed]`

## 9) Data import

Settings imports a validated data file after a review
([format](cookle-data-export-format.md),
[ADR 0012](../Decisions/0012-version-data-exports-with-the-swiftdata-schema.md)).
Reviewing does not mutate data. With an empty library everything is added.
Otherwise the person chooses one method, and exporting current data first is
offered for each:

- **Merge** adds new items and updates matching items with the file's content;
  items only on this device stay.
- **Choose for Each Item** resolves each differing item individually.
- **Replace** deletes all current data and inserts the file's content. It is
  available only for a complete-library file (`contents.scope` of `all`).

**Matching.** File-local identifiers are not persistent identities. Recipe names
identify possible matches; recipe content determines equality. When any current
recipe with the name is identical, the file's recipe is unchanged and reuses the
oldest identical one. Otherwise the recipe differs. Per item, the choices keep a
selected current recipe, update it in place from the file, or add a separate
recipe; Merge updates the oldest candidate that no other imported recipe keeps
or updates, and adds a separate recipe when none is left. Imported diary
references follow that choice. Updating a current recipe also changes what its
existing diary references display. `[runtime confirmed]` —
`CookleDataImportRecipeTests` and `CookleDataImportMergeTests`.

Diary matching uses the review's calendar day. A day is unchanged when its note
and, in order, each meal's type and recipe name match, so editing a recipe does
not make the days that show it differ. Differing same-day diaries are kept,
replaced (Merge always replaces), or combined. Combining preserves the larger
occurrence count for each recipe and meal type, keeps existing row order,
appends missing rows from the file, and retains different notes with a
separator. An existing duplicate day must be resolved before that day can be
imported. Unrelated records remain in place. `[runtime confirmed]` —
`CookleDataImportDiaryTests` and `CookleDataImportMergeTests`.

**Applying.** Merge and per-item imports validate the archive, bind approval to
its content, recheck current affected data, and validate all choices before a
single save. Stale review requires renewed confirmation. Photos are reused only
when both bytes and source match; new tags keep the file's timestamps; repeated
note combinations do not append the same note again. A failed merge preserves
the original on-disk recipe, photo rows and diary references after reopening.
Replacement binds its approval to the file and the complete current library,
including standalone records and data absent from the file. A changed review
returns to the import screen for renewed confirmation. Both import paths reject
unrelated unsaved edits before entering their save/rollback boundary.
Replacement validates the whole file before deleting anything and rolls back on
a failed save; it gives every record a new identity, so open screens, routes,
and cooking snapshots pointing at old records no longer resolve.
`[runtime confirmed]` — `CookleDataImportSafetyTests`,
`InterruptedReplacementTests`, `RejectedImportPreservationTests`, and
`ReplacementInvalidationTests`, and `ReplacementReviewSafetyTests`.

Import does not supply automatic undo, and a local rollback does not reverse
writes already synchronized elsewhere. Exporting beforehand preserves recovery
material. With iCloud sync enabled, an applied import is an ordinary local save:
its inserts, in-place updates, and replacement deletions synchronize like any
other edit, and the review compares the file only with data already on this
device. Edits another device makes before or after convergence are not part of
the review and follow normal synchronization. `[source confirmed]` Two-device
iCloud convergence remains a separate verification requirement.
