# Cookle Data Export Format

Format version 1, schema version `1.0.0`. Source review October 25, 2026.

This note specifies the file that Settings → Export Data writes and Import Data
reads. [ADR 0012](../Decisions/0012-version-data-exports-with-the-swiftdata-schema.md)
records why the format is versioned this way.

## 1) Container

A `.cookle` file is a package directory with the uniform type
`com.muhiro12.Cookle.data`, conforming to `com.apple.package`:

```text
Cookle-Export-20260929-101500.cookle/
├── manifest.json
└── photos/
    ├── photo-000001.jpeg
    └── photo-000002.heic
```

The root holds exactly `manifest.json` and `photos`. Symbolic links, extra
entries, and nested folders are rejected.

## 2) Manifest

`manifest.json` is UTF-8 JSON with sorted keys. Dates are ISO 8601 strings.

<!-- markdownlint-disable MD013 -->
| Field | Type | Meaning |
| --- | --- | --- |
| `format` | string | Always `com.muhiro12.Cookle.data` |
| `formatVersion` | integer | Container and encoding version, currently `1` |
| `schemaVersion` | string | SwiftData schema that wrote the records, currently `1.0.0` |
| `contents.scope` | string | What the file covers; `all` is the complete library |
| `exportedAt` | date | When the file was written |
| `ingredients` | array | Ingredient tags: `id`, `value`, timestamps |
| `categories` | array | Category tags: `id`, `value`, timestamps |
| `photos` | array | Photo metadata; bytes live in `photos/` |
| `recipes` | array | Recipes with ordered rows that reference other records |
| `diaries` | array | Diary days with ordered meal rows that reference recipes |
<!-- markdownlint-enable MD013 -->

Every record has `createdTimestamp` and `modifiedTimestamp`.

- A **photo** has `id`, `filename`, `byteCount`, `sha256` (lowercase hex of the
  file's bytes), and `sourceID`, the stored `PhotoSource` code: `zW8rLxK4` for
  a photo the person picked and `Xe1Vt9bQ` for an Image Playground image.
- A **recipe** has `id`, `name`, `servingSize`, `cookingTime` (minutes, `0`
  when unknown), `steps` in order, `note`, `categoryIDs`, `ingredients` rows
  (`ingredientID`, `amount`, `order`), and `photos` rows (`photoID`, `order`).
- A **diary** has `id`, `date`, `note`, and `objects` rows (`recipeID`, `type`
  of `breakfast`, `lunch`, or `dinner`, and `order`). Each calendar day has at
  most one diary. V1 encodes the meal enum as an object such as
  `"type": {"breakfast": {}}`, rather than a plain string.

Identifiers such as `recipe-1` are local to one file. They connect records
inside the file and never identify records across files or devices.

## 3) Photo files

The photo at manifest position *n* is named `photo-` followed by *n* as six
digits, then an extension naming its image type, such as `jpeg`, `heic`, or
`png`. Bytes that are not a recognized image use `data`. Readers match files by
the manifest's `filename`, `byteCount`, and `sha256`, not by the extension.

## 4) Scope and completeness

Every file is referentially complete: each ID a record references is present in
the same file. With scope `all`, the file also holds tags and photos that no
recipe references. Any other scope is a partial file. Readers accept scopes they
do not recognize and treat them as partial.

## 5) Reading rules

The supported pair for `com.muhiro12.Cookle.data` is currently:

| `formatVersion` | `schemaVersion` | Reader |
| --- | --- | --- |
| `1` | `1.0.0` | V1 manifest and photo package |

Other combinations are unsupported. A future reader retains supported published
pairs explicitly; it does not infer support from the store migration plan or
accept every combination of individually known version numbers. Representation
changes use `formatVersion`; actual model-version changes also change the
exported `schemaVersion`, even if the file's values are unchanged.

- The former `com.muhiro12.cookle.data` identifier used by 4.0 and 4.1 is
  intentionally unsupported after the namespace correction. Older builds also
  reject exports with the corrected identifier. The package layout, schema,
  and on-device store are unchanged; there is no identifier alias or fallback.
- `format` must match and `formatVersion` must be supported.
- `schemaVersion` must be one this build reads. A newer version asks the person
  to update Cookle.
- Resource limits: manifest 64 MiB, one photo 32 MiB, all photos 256 MiB, whole
  package 320 MiB, 10,000 records per top-level array, 100,000 nested rows,
  1 KiB per identifier, and 64 KiB per text field.
- Duplicate identifiers, missing references, and two diaries on one calendar day
  are rejected. Nothing changes when a file is rejected.

Historical readers decode values and adapt them into the current reviewed
import. They need not execute SwiftData migrations. When an old file lacks a
later field, its absence cannot clear an existing value; explicit emptiness in
a format that defines the field remains a separate reviewed choice. See
[ADR 0012's compatibility verification](../Decisions/0012-version-data-exports-with-the-swiftdata-schema.md#compatibility-verification)
for fixture retention and the separate store-migration and file-import checks.

## 6) Importing

Importing into an empty library adds everything. Otherwise the person merges,
chooses for each differing item, or — for scope `all` only — replaces all data.
[The mutation semantics note](cookle-mutation-semantics.md) section 9 describes
matching and each method.

## 7) Verification coverage

`ExportFileVersionTests` pins the current writer header and reader registration,
decodes a frozen hand-authored V1 contract fixture without today's encoder, and
checks unsupported headers. The fixture is synthetic contract evidence, not an
export captured from a released app.

`ArchivePersistentStoreTests`, `CookleDataImportRecipeTests`,
`CookleDataImportDiaryTests`, and `CookleDataImportSafetyTests` cover existing
graph preservation, edited destinations, repeated import, stale review, and
failure handling. `RejectedImportPreservationTests` proves rejected files leave
an existing store readable after reopening. The persistence tests, including
`LegacySchemaMigrationTests` and `LegacyStoreUpgradeFidelityTests`, independently
cover store paths. These existing tests do not prove a future V1-to-V2 file
adapter or the preservation of fields that V1 cannot express; add those cases
with the concrete transition and retain actual public-writer captures.
