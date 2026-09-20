# Preserve SwiftData storage contracts

## Decision

Keep the eight persisted models in `CookleSchemaV1` and expose the existing
model names through type aliases. The current stored fields, relationship names,
optionality, inverse relationships, delete rules, and version identifier remain
unchanged. App release numbers are independent of database schema versions.

`CookleMigrationPlan.currentSchema` selects the destination explicitly. When a
stored declaration changes, add a new version with its own model definitions,
retain the old declarations, update the aliases and destination, and add the
required ordered migration stages. Never edit a historical stored declaration
in place. Preserve the persisted encoding of `DiaryObjectType` and photo source
identifiers as part of this contract.

## Container ownership

The app owns writable startup, relocation, schema migration, and optional
CloudKit synchronization. Widgets use the same store location with a separate
read-only container, no migration plan, and CloudKit disabled. A missing or
incompatible store produces the existing widget error state; opening the app is
required before the widget can read it. App Intents hosted by the app continue
to use the app's injected container.

Retain the current default store location and App Group entitlement. Do not
change store names, URLs, or CloudKit identifiers merely to make configuration
more explicit. Such a change requires independent relocation and sync evidence.

Relocation validates the copied store locally with CloudKit disabled. Diagnostic
reads of the old store are read-only. Start synchronization only on the final
app container. If a destination already exists, replace it only when all eight
entities are proven empty. If it contains records or cannot be inspected, fail
without replacing either store. Resolve conflicting stores through explicit
recovery; retrying startup must not silently choose one copy over the other.

Do not run detached-row deletion at startup. CloudKit can deliver a row before
its parent relationship, even if the current launch has sync turned off. A nil
parent does not establish that a persisted row is disposable. Normal confirmed
mutations continue to remove their explicitly owned child rows. Historical
unlinked rows may remain until a separately justified repair is available.

## Model assessment

- Optional relationships, inverse links, default scalar values, and the absence
  of uniqueness and deny constraints fit the CloudKit storage requirements.
- Recipe and diary child rows retain ordering and per-link metadata. Shared
  ingredients, categories, and photos remain independent entities.
- Flattened relationships coexist with ordered rows in the deployed schema.
  Keep their storage identities; removing them needs a separate migration and
  compatibility design for older syncing clients.
- Photo bytes remain in their existing storage representation. External storage
  and indexes are possible performance work, not prerequisites for versioning.
  Measure first and verify migration and relocation before adopting them.

## Evidence and limits

The compatibility tests reconstruct the 3.9 stored declarations independently
of the production types. They create versioned and unversioned disk stores,
then verify current reads, reopening, scalar content, shared graph identity,
photo bytes, store UUID, persisted identifiers, and model version hashes.

The 2.7 reconstruction exercises the older schema without `Photo.sourceID`.
The current runtime performs that additive automatic migration without a new
explicit stage; the widget's read-only open rejects it before app migration.
This fixture is evidence for that historical shape, not a production V0 stage.
Before introducing a future staged migration, recover every supported historical
shape and test the complete path, including direct upgrades that skip releases.

These synthetic stores use the current SDK and CloudKit disabled. They do not
reproduce shipped binary metadata, historical OS bugs, or CloudKit history.
The earliest 1.x schemas include different optionality and are not covered by
these fixtures. Release validation must also cover supported older OS versions,
real historical stores, signed App Group access, widgets before/after host
launch, and old/new clients syncing in both directions. Local tests do not
establish production CloudKit readiness.

## Official references

- [Model your schema with SwiftData][schema] demonstrates separately retained
  version definitions, ordered stages, and the current destination schema.
- [SwiftData Group Lab][lab] recommends app-owned migration and omitting migration
  plans from extensions, with error handling until the app opens the store.
- [Syncing model data across devices][sync] documents optional relationships and
  non-atomic relationship synchronization.
- [Adding and editing persistent data][animals] demonstrates model relationships
  and container injection. Its local uniqueness constraint is not suitable for
  Cookle's CloudKit-backed tags.
- [Backyard Birds][birds] demonstrates shared-library models and per-surface
  contexts. Its generated fixtures and simplified error handling are sample
  scaffolding, not migration or recovery guarantees.

[schema]: https://developer.apple.com/videos/play/wwdc2023/10195/
[lab]: https://developer.apple.com/videos/play/wwdc2026/8017/
[sync]: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
[animals]: https://developer.apple.com/documentation/swiftdata/adding-and-editing-persistent-data-in-your-app
[birds]: https://developer.apple.com/documentation/swiftui/backyard-birds-sample
