# Cookle Data Export Format

Format version 1, schema version `1.0.0`. Source review September 29, 2026.

This note specifies the file that Settings → Export Data writes and Import Data
reads. [ADR 0012](../Decisions/0012-version-data-exports-with-the-swiftdata-schema.md)
records why the format is versioned this way.

## 1) Container

A `.cookle` file is a package directory with the uniform type
`com.muhiro12.cookle.data`, conforming to `com.apple.package`:

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
| `format` | string | Always `com.muhiro12.cookle.data` |
| `formatVersion` | integer | Package layout version, currently `1` |
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
  most one diary.

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

- `format` must match and `formatVersion` must be supported.
- `schemaVersion` must be one this build reads. A newer version asks the person
  to update Cookle.
- Resource limits: manifest 64 MiB, one photo 32 MiB, all photos 256 MiB, whole
  package 320 MiB, 10,000 records per top-level array, 100,000 nested rows,
  1 KiB per identifier, and 64 KiB per text field.
- Duplicate identifiers, missing references, and two diaries on one calendar day
  are rejected. Nothing changes when a file is rejected.

## 6) Importing

Importing into an empty library adds everything. Otherwise the person merges,
chooses for each differing item, or — for scope `all` only — replaces all data.
[The mutation semantics note](cookle-mutation-semantics.md) section 9 describes
matching and each method.
