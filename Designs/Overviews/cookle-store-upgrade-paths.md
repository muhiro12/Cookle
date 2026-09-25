# Cookle Store Upgrade Paths

Source review updated September 26, 2026.

## Purpose

This note records which upgrades Cookle's persistence code actually supports
today, what it does when an upgrade cannot proceed, and what it does **not**
promise. It is the reference an upgrade or schema change should be checked
against before it ships.

It describes current behavior. Where something is a product decision that has
not been made, it is marked **Open**.

Related: [ADR 0011](../Decisions/0011-preserve-swiftdata-storage-contracts.md)
holds the storage contracts, and
[the mutation semantics note](cookle-mutation-semantics.md) covers what
individual mutations do once a store is open.

## 1) Where the store lives

`Database.url` is `ModelConfiguration().url`. `ModelConfiguration()` leaves
`groupContainer` at `.automatic`, which resolves to the single app group in the
target's entitlements — `group.com.muhiro12.Cookle`.

The app and the Widgets extension therefore open the same file **only because
both declare that one group and nothing else**. Declaring a second group on
either target, or dropping the entitlement, moves this URL into a per-process
container and splits the store with no error at all. That hazard is recorded in
a comment on `Database` itself; no test can catch it, because entitlements are
not visible to the library.

`Database.legacyURL` is the same file name under
`URL.applicationSupportDirectory` — where the store lived before the app group.

## 2) The one supported relocation

Startup runs `ModelContainerFactory.makeAppContainer`, which prepares store
files before opening anything:

1. **Protect a populated destination.** If both the legacy and current files
   exist, `protectPopulatedDestination` opens the current one read-only and
   fetches from every model type in the schema. If **any** record is found it
   throws `CocoaError(.fileWriteFileExists)` and nothing is moved. Only a
   store proven empty — the shape an older widget could create before the app
   had relocated — is allowed to be replaced. Both halves are pinned by
   `relocation_preserves_both_populated_stores` and
   `relocation_replaces_empty_destination_and_preserves_graph`.
2. **Relocate.** `DatabaseMigrator.migrateStoreFilesIfNeeded` copies the legacy
   files to the current location, skipping with a named reason
   (`sameLocation`, `missingLegacyStore`, `missingCurrentStore`) rather than
   guessing.
3. **Validate before cleanup.** `validateMigratedDataBeforeDeletingLegacyIfNeeded`
   opens the relocated store and logs a snapshot. A failure here is logged with
   the store state and rethrown, so the legacy copy is never deleted after a
   failed validation.
4. **Clean up.** Only then are the legacy files removed.

So the supported upgrade path is exactly one: **a pre-app-group store in
Application Support to the app-group store.** It is ordered so that at no point
is the only readable copy the one being deleted.

## 3) Schema history

`CookleMigrationPlan` records **one** released schema — `CookleSchemaV1`,
version `1.0.0` — and **no** migration stages. There is no released schema
transition to support yet.

Selection is explicit: every container is opened with
`CookleMigrationPlan.currentSchema`, never with `schemas[0]`.
`CookleMigrationPlanTests` pins the invariants that keep that meaningful once
a second schema exists — `currentSchema` is the newest recorded version, the
history is ordered and duplicate-free, and there is one stage per step.
`SchemaIdentityTests` separately freezes V1's entity and property names, because
`CookleSchemaV1.models` points at the live model classes and an edit to any
stored declaration would otherwise change the released schema silently.

## 4) What each process may do to the store

| Process | Opens with | May migrate | CloudKit |
| --- | --- | --- | --- |
| App | `makeModelContainer` + `CookleMigrationPlan` | yes | `.automatic` when iCloud is on, else `.none` |
| Widgets / extensions | `ModelContainerFactory.shared()` → `makeReadOnlyContainer` | **no** | `.none` |

`makeReadOnlyContainer` passes `allowsSave: false` and **no migration plan**, and
throws `CocoaError(.fileReadNoSuchFile)` when the file is absent. An
extension therefore cannot migrate the store, and cannot half-migrate it
either: if it ever meets a store the app has not upgraded yet, it fails to open
and the widget falls back to its placeholder rather than touching the file.
`extension_does_not_create_missing_store` and
`extension_reads_existing_store_but_cannot_save` pin both halves.

## 5) When an upgrade cannot proceed

`CookleAppBootstrapModel.loadAssembly` catches the failure, leaves
`appAssembly` nil, and publishes `failureMessage`. `CookleStartupView` shows
that message with a retry action.

**Nothing resets the store on a failed open.** There is no "start fresh" path on
this route: the user sees the failure and the file stays as it was. Deleting
persisted data requires the explicit Settings action
(`SettingsActionService.deleteAllData`).

## 6) Synthetic downgrade exposes a data-loss risk

Cookle defines no reverse migration stage. `StoreRecoveryTests` creates a
**synthetic** `FutureSchemaV2` using the current SDK: it contains the current
V1 model types plus a `FutureNote` entity. The test opens that store with the
current V1 factory, saves another recipe, then opens it with the synthetic V2
again. The expected observations are:

- V1 opens this fixture rather than rejecting it.
- The shared recipe records remain readable, including the recipe added by V1.
- The synthetic V2-only `FutureNote` records are no longer returned.

This is a regression characterization of one local schema shape on the test
runtime. It is **not** a run of an older released binary, a real future schema,
or a CloudKit-backed store. The schema/container lifetimes in the test also do
not reproduce separate app processes. It does not establish that every schema
downgrade behaves this way, or that every future V2 is readable by V1.

The practical boundary is that downgrade safety is **not guaranteed**. Before
shipping a schema change, verify the actual old/new binaries and stores and
preserve an independently readable recovery copy. A portable archive is a
separate compatibility contract: restoring it into an older app also depends
on that app accepting the archive version and representing its contents.

Nothing currently prompts for a backup before a schema change, because no
schema transition has shipped. Recovery planning is tracked in
<https://github.com/muhiro12/Cookle/issues/133>.

## 7) Open questions

- **Minimum supported app version.** The code supports one relocation and one
  current schema. Reconstructed legacy fixtures provide bounded compatibility
  evidence; they do not prove that every released store opens. Which released
  versions are *declared* supported, and which historical binaries/stores must
  be tested before a schema change, has not been decided.
- **Pre-upgrade backup.** Whether a schema change should require or offer a
  backup first, given that safe downgrade is not guaranteed.
- **Low storage and interruption.** The relocation is ordered safely, but
  behavior under a disk-full copy or a kill mid-relocation is not covered by a
  test today.
