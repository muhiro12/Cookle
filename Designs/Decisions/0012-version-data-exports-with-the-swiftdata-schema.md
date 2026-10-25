# ADR 0012: Version data exports with the SwiftData schema

- Date: 2026-09-29
- Status: Accepted
- Amendment: October 25, 2026, separates shared evolution semantics from file
  import execution; see [#162](https://github.com/muhiro12/Cookle/issues/162).

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
`com.muhiro12.Cookle.data` with the `.cookle` extension, displayed as
"Cookle Data". Its layout is specified in
[the export format overview](../Overviews/cookle-data-export-format.md).

The 3.9 `.cooklebackup` format and the never-exposed single-file JSON form are
intentionally unsupported. The 3.9 feature was public for a short time, and a
clean format was preferred over carrying that reader.

The October 22, 2026 amendment aligns the product component with the existing
`com.muhiro12.Cookle` namespace. The former `com.muhiro12.cookle.data`
identifier from 4.0 and 4.1 is intentionally unsupported, with no reader alias
or fallback. This spelling correction was chosen during the feature's early
rollout rather than carrying a second identifier. Exports must be created and
read by builds using the same identifier. The package layout and record schema
are unchanged, so neither version number changes, and the on-device store is
unaffected. The schema-reader policy below applies within the corrected format.

### Versions

An export file carries two numbers with separate jobs:

- `formatVersion` versions the package layout, manifest envelope, and encoding
  conventions. Representation-only changes use this number without inventing a
  SwiftData schema revision.
- `schemaVersion` versions the records. It is the
  `versionIdentifier` of the `CookleMigrationPlan` schema that wrote the file,
  written as `major.minor.patch`.

The exporter always writes the current schema, using the actual
`versionIdentifier` rather than a second manually maintained number. Read
support belongs to explicitly supported `(formatVersion, schemaVersion)` pairs
used by exports, not every possible combination or every store-only schema.
Keep readers for supported published pairs, including skipped-version paths.
The existing identifier exceptions above remain unchanged.

A file from a newer schema is reported as needing a newer Cookle rather than as
damaged. Unsupported identifiers, format versions, and schema versions are
rejected before mutation. Do not partially import known fields from an unknown
version. The [format overview](../Overviews/cookle-data-export-format.md)
records the current support matrix.

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

Store upgrades and historical-file imports share preservation rules, not a
required execution mechanism. For each concrete transition, define the meaning
of identities, missing fields, units, precision, ownership, ordered
relationships, recipe/Diary references, and photo bytes/source once. Implement
those rules in each path using the appropriate mechanism.

The default file path is a frozen historical value decoder followed by an
explicit adapter into the current import candidate, then the existing
validation, review, and approved apply path. Native lightweight or custom
SwiftData migration handles the store. Share pure value-conversion functions
where there is real common logic; neither common model types nor identical
source code are required. Do not add a generic migration framework solely to
avoid a small adapter.

This replaces the earlier mandatory temporary-store sequence. Creating and
reopening a temporary database solely to reuse migration stages adds file
lifecycle, migration side effects, and failure paths to a value conversion. A
temporary store remains an option only when a concrete transition demonstrates
that it is simpler and reliable, with ordering, image preservation, cleanup,
and failure behavior verified. It must not replace the live store or rewrite
the source file.

An old file cannot express fields introduced later. For an existing record,
retain those current fields even when the person chooses the file's supplied
content. For a new record, use a documented compatibility default or an
explicit unknown state. Historical absence and explicit `null` in a format that
defines the field are distinct; applying the latter may be a reviewed change.
Carry field availability in the transient candidate or adapter, without adding
provenance columns to the live models. Do not turn current initializer defaults
into apparent old facts or infer deletion from a missing record kind. Block a
conversion that cannot preserve meaning instead of silently losing information.

When `CookleSchemaV2` ships:

1. Freeze the supported V1 representation and retain its reader and fixtures.
   Register each actually exported format/schema pair. Reuse a decoder when
   a storage-only schema revision leaves the wire representation unchanged.
2. Implement the concrete V1-to-current semantic adapter, preserving field
   availability through review and application into an already-edited store.
3. Verify store migration/reopen separately from old-file decoding and import.
   Identical version numbers or a passing migration test prove neither path's
   behavior on the other path.
4. Decide whether the first launch that runs a migration stage keeps a copy of
   the pre-migration store files. That launch is the schema-linked moment when a
   recovery copy matters most.

### Compatibility verification

- Retain synthetic exports captured from each supported public writer, with
  writer revision and version-pair provenance. Never regenerate old fixtures
  with the newest encoder. Hand-authored contract fixtures supplement those
  captures; a current writer/reader round trip does not establish historical
  compatibility.
- Exercise every supported published pair against the new reader. Freeze old
  field meanings, date units, requiredness, and defaults; fix reader bugs with
  regression evidence rather than reinterpreting past files.
- Cover decoding and reviewed import into both empty and edited current stores:
  field absence versus explicit emptiness, unrelated/newer values, repeated
  import, relationship ordering/references, photos, and failed-save recovery.
- Keep rejected-version tests that reopen an existing store and prove it is
  unchanged. Keep actual old-store migration/reopen tests independent of these
  file tests. No concrete V2 transition is implemented by this amendment.

## Consequences

- One number tells people and tools which data shape a file holds, and schema
  work cannot silently skip the export format.
- Import handles both recovery and moving devices, while merge and per-item
  choices keep other data safe.
- Historical file readers and fixtures remain explicit compatibility contracts;
  ADR 0011 independently preserves the stored schema declarations.
- Not decided here: sharing, AI hand-off formats, reminders, opening files from
  Files or AirDrop, and new entry points.
