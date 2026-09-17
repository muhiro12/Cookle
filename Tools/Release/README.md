# Cookle release tools

This isolated macOS SwiftPM package pins Apogee **1.2.0** for Cookle release
preparation. The published tag resolves to
`90b2a6c4dfe046fe9e1716da18321a78ee06bd90`. Commit `Package.resolved` with any
intentional dependency update. No app, library, Widget, or Watch target links
Apogee.

Xcode Cloud remains responsible for formal builds, tests, and archives.
A successful release-tool command does not qualify the app for distribution.

## Setup

Run from the repository root using the selected Xcode toolchain:

```sh
xcode-select -p
xcodebuild -version
swift package --package-path Tools/Release resolve
swift package --package-path Tools/Release plugin \
  --allow-network-connections all apogee -- --help
```

SwiftPM builds the pinned command plugin and executable on first invocation.
The plugin runs in `Tools/Release`, where it discovers `apogee.json`.
Configuration-relative metadata paths resolve beside that JSON file; explicit
CLI paths resolve from the plugin's working directory. Use absolute CLI paths
to avoid ambiguity.

## Prepare and validate metadata

Keep version-specific inputs in ignored `AppStore/Metadata/`, or another private
directory. Use actual App Store Connect locale identifiers, not Xcode language
codes. Confirm the selected version's locales before any remote write.

For example, a metadata directory can contain:

```text
<version>/
  en-US/release_notes.txt
  es-ES/release_notes.txt
  fr-FR/release_notes.txt
  ja/release_notes.txt
  zh-Hans/release_notes.txt
```

Validate the intended input before configuring credentials:

```sh
export RELEASE_METADATA_PATH="/absolute/private/path/to/intended-version"
swift package --package-path Tools/Release plugin \
  --allow-network-connections all apogee validate-metadata \
  --metadata-path "$RELEASE_METADATA_PATH" --release-notes-only
```

Validation checks local UTF-8 files and safe paths without credentials or App
Store Connect requests. SwiftPM may fetch dependencies. It does not establish
Apple's locale support, field length limits, account permissions, or editability.
Omit files for unchanged fields; an empty file requests clearing that field.
Do not use temporary text or an invented version for a remote rehearsal.

## Authentication and read-only status

Apogee 1.2 uses an App Store Connect team API key. Store its private key outside
the repository with owner-only access. Configure the execution shell locally:

```sh
export ASC_KEY_ID="YOUR_TEAM_KEY_ID"
export ASC_ISSUER_ID="YOUR_TEAM_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="/absolute/private/path/to/AuthKey_YOUR_TEAM_KEY_ID.p8"
```

Apogee does not load `.env` files automatically. A nonempty
`ASC_PRIVATE_KEY_BASE64` overrides `ASC_PRIVATE_KEY_PATH`. Keep credentials,
tokens, account output, and unpublished metadata out of Git and public issues.
The configured app ID selects Cookle; it does not restrict the key's permissions.
See [Apple's API key setup][api-keys].

Read an explicitly selected existing version:

```sh
export RELEASE_VERSION="ACTUAL_EXISTING_VERSION"
swift package --package-path Tools/Release plugin \
  --allow-network-connections all apogee release-status \
  --app-id 6483363226 --platform IOS --version "$RELEASE_VERSION"
```

Confirm the version, attached build, review state, and release timing against
App Store Connect. Read-only status does not prove write access.

For a new Cookle version, first confirm that the exact version does not already
exist. Then inspect the read-only creation plan:

```sh
export RELEASE_VERSION="ACTUAL_NEW_VERSION"
swift package --package-path Tools/Release plugin \
  --allow-network-connections all apogee create-version \
  --app-id 6483363226 --platform IOS --version "$RELEASE_VERSION" \
  --dry-run
```

After the plan and release decision are approved, replace `--dry-run` with
`--apply`. Apogee creates only a manual-release version resource and verifies it
by reading it back. It does not update metadata, attach a build, submit for
review, or publish the version. If apply times out or verification fails, run
`release-status` and inspect App Store Connect before retrying; creation is not
automatically retried or rolled back.

Before changing metadata, save a fresh read-only snapshot to a new private file:

```sh
export RELEASE_SNAPSHOT_PATH="/absolute/private/path/to/metadata-snapshot.json"
swift package --package-path Tools/Release plugin \
  --allow-network-connections all apogee read-metadata \
  --app-id 6483363226 --platform IOS --version "$RELEASE_VERSION" \
  --save-to "$RELEASE_SNAPSHOT_PATH"
```

Apogee never overwrites an existing snapshot path. The snapshot contains full
localized metadata and App Store resource identifiers, so keep it out of Git,
logs, and public issues.

## Review and apply release notes

Select the actual editable version and complete localized text. Preserve the
current remote values with `read-metadata`, then inspect the diff:

```sh
swift package --package-path Tools/Release plugin \
  --allow-network-connections all apogee update-release-notes \
  --app-id 6483363226 --platform IOS --version "$RELEASE_VERSION" \
  --metadata-path "$RELEASE_METADATA_PATH" --dry-run
```

For the approved operation, replace `--dry-run` with `--apply`. Read back every
selected field, then rerun the same dry-run and confirm no remaining changes.
Do not overwrite unrelated fields or locales. Keep raw plans in ignored
`AppStore/Plans/` or other private storage.

Commands that render status or plans also accept `--output json`. JSON is
written only after a successful operation; failures stay on standard error with
a nonzero exit status. Check the exit status, `schemaVersion`, result kind,
command, mode, and target before consuming it. An apply can fail after a remote
write, so empty standard output is never evidence that nothing changed.

Build attachment and review submission are separate release decisions. Record
the exact candidate commit, Cloud toolchain/build, tests, signed archive,
TestFlight checks, metadata, and remaining product gates before submission.
Treat screenshot updates and version-setting writes as separate release
decisions. Follow Apogee's dry-run, private recovery, and read-back requirements
before applying them. Apogee does not manage Xcode Cloud workflows.

After release, review availability, crash/sync reports, and user feedback for
the selected version. Pause a phased release where appropriate and prepare a
corrective release if needed. Do not assume that a previous binary can read a
newer SwiftData schema.

## Remaining qualification

Package resolution, plugin execution, offline validation, version-creation
planning, and snapshot export are the tooling adoption boundary. Account access,
remote create/write/read-back, and the full release rehearsal remain tracked in
[Cookle #125][release-issue].

[api-keys]: https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-api/
[release-issue]: https://github.com/muhiro12/Cookle/issues/125
