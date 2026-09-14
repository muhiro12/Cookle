# September Release Readiness

Temporary verification record, September 7-13, 2026. Retained for the transition
to post-release work. The near-term development brief remains the execution
instruction. Dated review sections below preserve their original evidence and
decisions; this current decision supersedes their release holds.

## Decision

**Cookle 3.9 is released. Proceed to post-release preparation.** The release
milestone in the near-term brief is complete. Existing defects and unverified
scenarios remain follow-up work rather than reasons to treat the published
release as still pending. On September 14 the expanded MHUI Recipe Detail
comparison was accepted. Main-app adoption proceeds under
[ADR 0009](../Decisions/0009-adopt-full-mhui-in-main-app.md), with the broader
[screen rollout and evidence](mhui-app-rollout.md) kept separate from the
completed Cookle 3.9 release. Dated entries below preserve their historical
evidence and gates.

## September 13 Release Confirmation

The public Apple lookup returned Cookle 3.9 for `com.muhiro12.Cookle`, with a
release timestamp of September 13, 2026 at 09:47:43 JST. The published Japanese
release notes match the finalized notes, including removal of the backup
prerequisite paragraph.

[GitHub Release 3.9][release-39] is published, not a draft or prerelease. Its
remote tag resolves to `816df9df32c65e638af7e881d9a876114f2b1aee`, matching the
verified candidate and remote main at the time of this check. The tag was
fetched locally without changing its target.

<!-- markdownlint-disable MD013 -->
| Evidence | Result | Scope |
| --- | --- | --- |
| Public App Store | Version 3.9 available | Japanese storefront |
| GitHub release and tag | Published; candidate commit matches | Tag 3.9 |
| Cloud Build 459 | Tests, archive, exports, TestFlight passed | Same commit |
| Cloud library tests | 1,108 executions passed on four destinations | Simulator |
| Production recipe sync | Updated iPhone to updated iPad passed | User-reported |
<!-- markdownlint-enable MD013 -->

The user created a recipe in the released iPhone app and viewed it in the
released iPad app. This provides real-device production evidence for that
recipe creation and synchronization path. It was not independently repeated
by the agent and does not establish reverse synchronization, photo fidelity,
offline recovery, purchase restoration, or destructive backup behavior.

Cloud evidence from September 10 was reused after checking its commit and
retained artifact hashes. No fresh build or test run was necessary for this
release-metadata and documentation check. The public lookup does not expose
the production build number; that number was not independently retrieved from
App Store Connect during this check.

The September 12 source comparison found no stored-property, relationship,
schema-version, migration-stage, entitlement, or persistence-key definition
change from 3.8. The new backup package format remains a file-compatibility
responsibility for future versions.

### Follow-Up Scope

- The subscription catalog-failure defect also exists in 3.8. This release
  does not adopt its fix; successful normal synchronization does not prove
  the failure path fixed. Track package adoption as separate follow-up work.
- Privacy declarations still need comparison with actual SDK configuration
  and communication. No new privacy reconciliation was performed here.
- Same-day duplicate diaries are rejected by the new backup export and
  restore validation. Preserve this compatibility limitation as a follow-up;
  it is not evidence of automatic data loss on upgrade.
- Begin the next phase with fresh representative Cookle screens and visual
  acceptance criteria. Broad MHUI adoption follows approval and must include
  the ADR, documentation, and consumer-boundary updates in the brief.

## September 10 Subscription Fix and Follow-Up

The released StoreKitWrapper 1.2 source was exercised in an isolated macOS app
host with Apple's `SKTestSession`. A verified local subscription remained in
`Transaction.currentEntitlements` while an injected network error made
`Product.products(for:)` fail. The original Product-based callback reported an
empty set. The test failed before the fix. This is a reproduced SDK-boundary
defect, not merely a source-level suspicion or a real-account test.

StoreKitWrapper commit `30baaa6` separates verified purchased identifiers from
catalog metadata. It adds an identifier callback, observable loading/errors,
replacement/cancellation of owned observation, and a stop operation. The legacy
Product callback waits for complete metadata instead of falsely reporting no
purchase. Verified empty entitlements still report inactive. The package-owned
subscription-section presentation and minimum OS versions remain unchanged.

<!-- markdownlint-disable MD013 -->
| Boundary | Current evidence |
| --- | --- |
| StoreKitWrapper unit tests | 9 passed, no failures/skips, Xcode-native macOS |
| Shipping-compiler package tests | The same 9 passed with Xcode 26.6 on macOS |
| iOS package compilation | Xcode-native iOS Simulator build passed |
| Apple StoreKit host | 5 cases passed; catalog and purchase/refund coverage |
| MHPlatform candidate | 328 tests passed on the dedicated iOS 18.6 Simulator |
| Adopting applications | Candidate integration and StoreKit behavior unverified |
<!-- markdownlint-enable MD013 -->

The hosted tests use synthetic product identifiers and Apple's Xcode StoreKit
environment. They prove neither production-account purchase restoration nor
Cookle's iCloud preference retention. Two test functions produce five executed
cases because one function has four parameter combinations.

A local MHPlatform candidate forwards the identifier callback and skips StoreKit
startup when no subscription identifiers are configured. Its tests passed after
preserving the nonisolated view-building API in StoreKitWrapper. The adapter
patch is retained in local verification artifacts, not applied to MHPlatform
main. It requires a published StoreKitWrapper revision containing the new API
and a corresponding dependency minimum before adoption.

Incomes and Cookle consumer copies were prepared for isolated integration.
Incomes built successfully with the existing released packages; source paths
proved that this did not use the candidate. Workspace references did not
activate the expected override. The standard Xcode Add Local flow then failed
with an unresolved filesystem dependency graph. This is a concrete integration
verification blocker, not a candidate consumer build pass. No package tags,
pushes, or application dependency pins were changed.

### File Picker, iPad, and Shipping Archive

A dedicated, initially empty iPhone 16 Simulator running iOS 18.6 displayed the
Japanese Diary, Settings, Restore Backup Files picker, and Settings again after
Cancel. The picker contained search, tabs, and cancel controls; the earlier
blank sheet did not reproduce. No backup file was selected or restored.
The app process was stopped after observation. Existing devices and data were
preserved. This does not clear shipping-toolchain or representative-data gates.

A separate dedicated iPad Pro 11-inch Simulator running iOS 18.6 also showed
landscape Diary, Settings, the native Files picker, and return after Cancel.
No overlap or clipping was observed in those screens. The Settings Shortcuts
button omitted the app name, rendering the Japanese suffix alone. Its runtime
log reported AppIntents metadata extraction failure. This is a visible label
and metadata follow-up with unconfirmed ownership; retest the shipping build
and actual Shortcuts behavior before selecting a source fix.

Xcode 26.6 (`17F113`) was explicitly selected for a generic-iOS-device Release
archive attempt. Dependency resolution completed, but the archive stopped
before compilation because the required iOS 26.5 platform component was not
installed. No signed archive was produced. Xcode 27.0 beta (`27A5252f`) results
remain separate from distribution evidence.

The public privacy label still says Data Not Collected. Resolved Google Mobile
Ads 12.14.0 and UMP 3.1.0 device-framework manifests were saved and hashed.
Their declared behavior still requires reconciliation with actual app consent,
network behavior, the archive privacy report, and App Store Connect answers.
App Store Connect remained login-required; unpublished answers were not read
or changed. Five localized What's New drafts were prepared, with no publication
or assumed release date.

The September 10 analyzer result for `3.8..ac5b2f2f` remains **75/100, Hold for
review**. The confirmed, unadopted entitlement fix independently prevents
release clearance; the heuristic score is not a defect probability. Local
artifacts under `.build/release-completion-20260910/` contain before/after test
results, the adapter patch, release-note drafts, screenshots, and the Japanese
visual report. The pre-existing shared scheme metadata diff is excluded from
this documentation change.

## September 9 Restore Rollback Fix

A new disk-backed regression test reproduced a SwiftData crash when a backup
replacement failed to save with existing photo, recipe, ingredient, category,
and diary relationships. The isolated failure reached `context.rollback()`
and reported:

```text
Unexpected backing data for snapshot creation:
SwiftData._FullFutureBackingData<CookleLibrary.PhotoObject>
```

`DataResetService` previously deleted parents before fetching and deleting
their owned child rows. It now deletes diary, photo, and ingredient child rows
before parent records, preventing the reproduced rollback snapshot failure.
No schema, public API, package, or deployment-target change was needed.

`ArchivePersistentStoreTests` uses disposable SQLite stores with CloudKit
disabled and a 1 MiB photo payload. It checks complete archived content after
reopening the store, including bytes, relationships, ordering, and timestamps:

- Legacy JSON export and restore into a populated destination store.
- Package export and restore into a populated destination store.
- Injected save failure preserving original content in the rollback context
  and after opening a fresh container.

The failure reproduced alone before the fix. Afterward, all 277 library test
cases passed with no failures or skips. The Cookle native build, formatter,
SwiftLint, retained repository rules, and `git diff --check` passed.
Verification used Xcode 27.0 build `27A5252f` and iOS 27 Simulator.
The original Cookle scheme and iPhone 17 Pro for Fluel destination were
restored and confirmed; no application interaction session was started.

This reduces a concrete failure-path risk. It does not establish behavior
under actual disk exhaustion, the shipping OS/toolchain, Files/iCloud Drive
selection, CloudKit synchronization, or paid subscription states. The earlier
blank file picker is a separate unresolved observation. StoreKit failure
injection remains the next independent reliability investigation.

## September 7-8 Reviewed Candidate

- Baseline: release tag `3.8`.
- Candidate: `cdac2808`, marketing version `3.9`.
- Range: 60 commits and 223 changed files.
- Product code is unchanged from the prior `120e9058` verification.
- Initial tracked and untracked working tree: clean.
- Scope: focused risk, identity, persistence, backup, subscription, privacy,
  retained rules, app build, and limited live UI smoke.
- This is not an exhaustive review of every changed line.

## Automated Evidence

| Capability | Result | Evidence scope |
| --- | --- | --- |
| Repository rules and SwiftLint | Pass, rerun | Static checks |
| CookleLibrary tests | 274 passed, 0 failed/skipped | Prior result verified |
| Cookle build and install/run | Pass, rerun | Debug, Xcode 27 beta |
| Widgets build | Prior pass retained | Same product code |
| Watch compilation | Included in prior app build | No live Watch proof |
| iPhone visual review | 7 usable states, 1 failed state | Empty app data |

The prior Xcode-native test result from September 7 at 23:22 JST was parsed
again from a disposable copy of its result bundle. It confirms 274 passing
tests, no expected failures, skips, failures, or recorded runtime warnings.
Tests and Widgets builds were not repeated because product code and the
tested boundary were unchanged.

The current app build log reported success with no warning or error entries.
This incremental result does not erase the previous Watch App Intents
metadata warning, or establish a warning-free distribution archive.

Toolchain: Xcode 27.0, build `27A5252f`; iOS 27 Simulator. The command-line
Developer directory points to Xcode beta. The installed non-beta Xcode app
reports version 26.6 in its bundle metadata, but the actual shipping Xcode and
Xcode Cloud configuration remain unconfirmed. The minimum deployment target
remains iOS 18.

## Runtime and Visual Findings

### Primary iPhone Screens

Mode: `diff-focused release smoke`. Device: `iPhone 17 Pro for Fluel`,
iOS 27, portrait app UI, 402 by 874 logical points, Japanese, light appearance.

Seven distinct states were visually usable:

- Diary empty state.
- New diary sheet, including calendar and meal rows.
- Recipe empty state.
- New recipe sheet.
- Photos empty state.
- Search root.
- Settings, including backup controls and deletion wording.

Both new-entry sheets returned to their empty roots after Cancel without
adding data. No blocking layout issue was observed in these seven states.
The Settings Debug row belongs to the development configuration.

### Blank Backup File Picker

Selecting Restore Backup showed a white sheet without file controls. The
initial action timed out; two subsequent no-interaction captures remained
blank. No file was selected and no restore was performed. This is an observed
UI failure in the tested environment, not a successful backup round trip.

The source uses the standard SwiftUI file importer. The available evidence
does not isolate ownership among the app, the system document picker, and
the integration. Retest this transition on the shipping OS/toolchain before
choosing a source fix. Avoid replacing the importer based on this observation
alone.

### Capture and Runtime Limits

The workspace-backed capture initially returned `Session not found`. An
Xcode-native session for the already installed app recovered screenshots and
hierarchies. Several tab actions timed out, but a follow-up capture verified
the intended destination and the same live process.

The recovered session reported `NotRun` despite a visible app and live
hierarchy. Its log files were empty. A separate console query returned the
earlier expired launch, with a different PID. That log proves initial startup
only and cannot explain the later blank file picker.

The earlier launch log includes startup readiness, notifications disabled,
Watch unpaired, Simulator service errors, and slow WebKit subprocess startup.
No crash-free or error-free claim is made for the later recovery session.

### iPad Attempt

The discovered iPad Pro 11-inch (M5), iOS 27 destination was attempted for
landscape root and Settings coverage. Native build succeeded, but launch
failed after 120 seconds. Session initialization and recovery capture timed
out; the next capture reported that the Simulator could not be connected.
No iPad screenshot, orientation, or app-data state was observed. The recovery
session was stopped successfully. This is a tooling/runtime availability gap,
not visual approval or evidence of an iPad layout defect.

### Final Startup and Cleanup

A fresh Xcode-owned iPhone launch reached startup ready and wiring completion.
It logged removal of `SKTransactionUpdatesLastChecked` from the app's standard
preference domain. The source prunes undeclared keys, consistent with ADR 0006;
this observation alone does not establish the key's owner or functional
impact. Include preference cleanup effects in the subscription-state review.
It does not diagnose the earlier blank picker.

The original Cookle scheme was restored first, valid destinations were
rediscovered, and iPhone 17 Pro for Fluel was restored and confirmed. Native
RunProject then established a fresh process, PID 27710, and StopProject
confirmed stopping that exact PID. The older recovery PID 22838 was not
directly queried for termination; the final launch/stop is the current
cleanup evidence.

Screenshots, original capture paths, hierarchies, logs, and the Japanese visual
report are local review artifacts. They are not committed snapshot tests or
formal MHUI acceptance evidence.

## Focused Risk Review

The built-in analyzer scored **75/100, Hold for review**, with medium
confidence over `3.8..cdac2808`. This is heuristic triage, not a measured
probability of failure or a confirmed defect count. The strongest signals
were capability/configuration change and durable state; method and string
catalog changes also triggered conservative matches.

- Inspected model diffs change methods and error propagation, without stored
  property changes in those models.
- Bundle identifiers are retained; there is no entitlement diff.
- Backup validation precedes replacement, and save failure rolls back.
- Package round-trip and legacy JSON compatibility have library test coverage.
- Files, CloudKit upgrade, and existing-device restore remain separate checks.

Representative signature and version excerpts (parameters elided):

```diff
- public static func create(...) -> Photo
+ public static func create(...) throws -> Photo
- MARKETING_VERSION = 3.8;
+ MARKETING_VERSION = 3.9;
```

### Privacy Label Comparison

A direct browser observation of the
[Japanese public App Store page][store] showed version 3.8, June 30, and
"Data Not Collected." Search and cached page results varied in version, so
the direct browser observation is the basis for this finding.

The candidate's resolved Google Mobile Ads SDK 12.14.0 privacy manifest
declares seven collected data types: coarse location, device ID, advertising
data, product interaction, crash data, performance data, and other diagnostic
data. Its device-ID entry includes tracking. This is SDK-declared behavior,
not a capture of Cookle's actual network traffic.

[Apple's disclosure guidance][apple-privacy] includes third-party partners.
[Google's disclosure guidance][google-privacy] describes the SDK's collection.
Compare the actual configuration, consent behavior, archive privacy report,
and App Store Connect answers. Do not copy the SDK manifest into store
answers without that review.

App Store Connect opened at a login-required page. Unpublished 3.9 answers and
review status were not accessible, so the current submitted answers have not
been proven incorrect. The public label and SDK manifest are a concrete
reconciliation task, not evidence of a completed privacy review.

### Subscription Metadata Dependency

The resolved StoreKitWrapper 1.2.0 implementation filters verified current
entitlements through the successfully loaded `Product` catalog. If that
catalog is empty, a verified entitlement can still produce an empty
`purchasedSubscriptions` callback.

MHPlatform 1.12.0 maps that callback to inactive premium status. Cookle's
`syncSubscriptionStateIfNeeded` can then persist both subscription and iCloud
preferences as false during a lifecycle synchronization.

At the September 7-8 review, this was a source-confirmed conditional path and
was not reproduced in that Simulator session. The September 10 hosted test
above subsequently reproduced the defect. The Cookle dependency pin remains
unchanged, so the original path is still relevant to its release candidate.

## Historical Remaining Evidence on September 10

This was the checklist at the earlier review. The September 13 confirmation
above supersedes its publication and shipping-archive gaps. Other entries
describe unverified scenarios, not a new hold on post-release preparation.

1. Confirm the distribution Xcode, Xcode Cloud archive, and App Store Connect
   3.9 state. Reconcile the public privacy label and SDK behavior.
2. Complete StoreKitWrapper -> MHPlatform -> app adoption and verify the exact
   candidate sources in consumer build logs. Exercise unknown, inactive,
   active, restored, and product-metadata-failure subscription states; observe
   ad suppression and iCloud preference retention.
3. Retest the backup file picker with the shipping toolchain. Upgrade
   representative existing data and round-trip legacy JSON and package backups
   through Files or iCloud Drive.
   Compare records, photo bytes, and relationships; use two real devices where
   practical.
4. Verify notification delivery and destinations after relevant mutations and
   foreground/background transitions.
5. Execute representative recipe and diary Shortcuts through the system.
6. Verify actual Home Screen Widget content, refresh, and tap destinations.
7. Verify paired Watch cooking steps, timers, connectivity, and session end.
   No shared Watch scheme or live Watch evidence is available.

During those September 7-10 checks, no existing simulator data was erased or
seeded. Only disposable test-host transactions were created and cleared. Those
checks did not perform a production purchase, real-device restore, account
change, publication, or release tag creation.

## Full MHUI Adoption After Release

1. The September release is complete, as confirmed on September 13.
2. A fresh Recipe Detail baseline and two MHUI alternatives were captured
   from commit `0a9eda1`. The expanded option was selected on September 14.
3. The root and expanded Recipe Detail are implemented together with
   ADR 0009, README and architecture updates, and the consumer-boundary checks.
4. Continue broader adoption with screen-specific presentation decisions and
   focused before/after verification. Lists, forms, diary, cooking, search,
   settings, and media are not completed by the first slice.
5. Verify the affected package and app boundaries, native behavior,
   accessibility, size classes, and appearance modes. CookleLibrary,
   Widgets, and Watch remain outside this adoption.

The release and representative-screen approval gates are satisfied. See
[adoption status](mhui-1.18-comparison/adoption-status.md) for actual implemented
scope and verification; it does not establish readiness of the next release.

[store]: https://apps.apple.com/jp/app/cookle-%E3%83%AC%E3%82%B7%E3%83%94/id6483363226
[apple-privacy]: https://developer.apple.com/app-store/app-privacy-details/
[google-privacy]: https://developers.google.com/admob/ios/privacy/data-disclosure
[release-39]: https://github.com/muhiro12/Cookle/releases/tag/3.9
