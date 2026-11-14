# Debug capabilities

Settings > Advanced > Debug is available in every build. It does not depend on a
saved preference, a secret command, or a gesture. Advanced keeps the infrequent
entry below ordinary settings; closing Debug returns to Advanced, and Back
returns to Settings. Existing data-management confirmations and subscription
rules remain in their current settings flows.

## Distributed builds

Release, TestFlight, and App Store builds expose read-only status:

- App version and build number.
- Whether the current model container has iCloud enabled.
- The runtime's subscription state, including an unconfirmed state.
- Saved counts for all eight model types, including structural records.

Counts come from an independent read context. Reading status neither saves nor
rolls back pending edits. Counts describe this device's saved records, not
CloudKit convergence. Failures show a generic status-read error; record contents,
identifiers, filesystem paths, and raw error messages are not displayed.

The raw log console, editable model inspectors, direct inspector deletion,
subscription/ad previews, sample insertion, and TipKit test controls are compiled
only with `DEBUG`. The old recipe-name unlock and debug preference are removed.
The ordinary Show tips again action remains available in Settings.

## Development builds

Ordinary DEBUG startup opens `Application Support/CookleDevelopment/default.store`
inside the app sandbox, with CloudKit disabled. It does not open, migrate, or
fall back to the shared user database. A failure remains visible at startup.
Development assemblies isolate cooking sessions and Watch delivery and disable
Spotlight indexing. They use the existing development ad configuration without
bypassing subscription entitlements.

The first creation of this development store inserts the existing offline
`CooklePreviewStore` fixtures. Set
`CookleDevelopmentStore.automaticallyInsertsSamples` to `false` before creating a
fresh store to inspect empty states. Reopening an existing store preserves edits
and deliberate emptiness, regardless of that setting. A failed initial insertion
is reported; reopening does not silently retry it.

Create Preview Diaries remains a manual action independent of the initial-seeding
setting. Its operation checks the exact development store URL, rejects CloudKit,
shared, read-only, in-memory, and multi-configuration stores, requires no pending
edits, and checks all eight model types for emptiness. Fixture generation and the
single save run synchronously with autosave disabled; a failure rolls back only
those newly pending fixtures. Repeated insertion into a populated store is
rejected. Inspector deletion also requires the separate development store before
entering the existing guarded mutation workflow.

SwiftUI Previews and the specialized capture workflow retain their isolated
in-memory stores and existing fixtures. Their setup path is separate from manual
insertion into the persistent development store. Use a deliberately prepared
Release configuration to verify the normal user-store path.

## Scope

This implements the access and build-capability split proposed in #166. The
broader settings information-architecture review (#140) and fixture consolidation
and profiles (#152) remain separate work. No stored schema or export format
changes are part of this boundary.
