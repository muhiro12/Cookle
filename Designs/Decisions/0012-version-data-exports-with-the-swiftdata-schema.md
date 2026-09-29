# ADR 0012: Version data exports with the SwiftData schema

- Date: 2026-09-29
- Status: Accepted

## Context

Cookle 3.9 shipped a Settings "Backup" that wrote a `.cooklebackup` package and
restored it by replacing all data. Development after 3.9 changed the import to a
reviewed merge. The feature, however, is broader than a backup: it is the
person's own data written in a portable, documented form. Recovery after a
mistake and moving to a device without iCloud sync are uses of it, and later
features such as sharing selected recipes or handing data to other tools build
on the same file.

The earlier design also carried three unrelated version numbers — the archive
record format, the package container format, and the SwiftData schema — and the
file did not record which schema wrote it. Readers accepted exactly one value of
each, so the first change to any of them had no defined upgrade path.

## Decision

### Name and file type

The feature is **data export and import**. Settings offers "Export Data" and
"Import Data" as its only entry points. The file type is
`com.muhiro12.cookle.data` with the `.cookle` extension, displayed as
"Cookle Data". Its layout is specified in
[the export format overview](../Overviews/cookle-data-export-format.md).

The 3.9 `.cooklebackup` format and the never-exposed single-file JSON form are
intentionally unsupported. The 3.9 feature was public for a short time, and a
clean format was preferred over carrying that reader.

### Versions

An export file carries two numbers with separate jobs:

- `formatVersion` versions the package layout and manifest envelope. It changes
  only when the container itself changes.
- `schemaVersion` versions the records. It is the
  `versionIdentifier` of the `CookleMigrationPlan` schema that wrote the file,
  written as `major.minor.patch`.

The exporter always writes the current schema. The importer reads every schema
in `CookleMigrationPlan.schemas`; a test fails if a schema is added without a
reader. A file from a newer schema is reported as needing a newer Cookle rather
than as damaged. An unknown `format` or `formatVersion` is rejected as invalid.

A storage-only schema change, such as an attribute option, also produces a new
`schemaVersion` even when the exported records look the same. That cost is
accepted: App Store updates move forward, and downgrade safety is not promised
(see [store upgrade paths](../Overviews/cookle-store-upgrade-paths.md)).

### Importing

Validation completes before anything changes. When current data is empty,
everything in the file is added. Otherwise the person chooses one method:

- **Merge** adds new items and updates items that match a recipe name or diary
  day with the file's content. Items only on this device stay. The choices come
  from `CookleDataImportSelections.updatingMatchingData(for:)` and are applied
  through the same reviewed, single-save path as per-item choices.
- **Choose for Each Item** resolves each differing item individually.
- **Replace** deletes all current data and inserts the file's content. It is
  offered only for a file whose scope is the complete library.

Exporting current data first is recommended for every method. None of them
provides undo, and with iCloud sync on, the result synchronizes like any edit.

A diary day matches the current day when its meals, in order, show recipes with
the same names and its note matches. A recipe edit therefore does not turn every
day that shows the recipe into a conflict. Among current recipes sharing a name,
one with identical content makes the imported recipe unchanged.

### Partial files

Every file is referentially complete: a record's photos, ingredients,
categories, and — for diaries — recipes are in the same file. `contents.scope`
states what the file covers. Only `"all"` includes records that nothing
references, and only `"all"` can replace current data. Readers accept scopes
they do not know and treat them as partial, so adding a way to export selected
recipes or a diary period needs no `formatVersion` change and stays readable by
older builds.

Selection is not implemented yet. When it is, one function that extracts
chosen records and their references from a `CookleDataArchive` serves both
export and a future "import only part of this file". The duplicate-diary-day
export check then applies only to exports that include diaries.

### Introducing the next schema

When `CookleSchemaV2` ships:

1. Keep the V1 record decoder and add the V2 one; register both.
2. Read a V1 file by inserting its records into a temporary store opened with
   `CookleSchemaV1`, reopening that store with `CookleMigrationPlan`, and
   passing `makeArchive(context:)` of the migrated store to the import review.
   Migration stages then remain the only place that reshapes data.
3. Decide whether the first launch that runs a migration stage keeps a copy of
   the pre-migration store files. That launch is the schema-linked moment when a
   recovery copy matters most.

## Consequences

- One number tells people and tools which data shape a file holds, and schema
  work cannot silently skip the export format.
- Import handles both recovery and moving devices, while merge and per-item
  choices keep other data safe.
- Old export readers must be retained as long as the matching schemas are, which
  ADR 0011 already requires for stored declarations.
- Not decided here: sharing, AI hand-off formats, reminders, opening files from
  Files or AirDrop, and new entry points.
