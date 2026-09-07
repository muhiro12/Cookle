# September Release Readiness

Temporary verification record, September 7, 2026. Remove or replace after the
release. The near-term development brief remains the execution instruction.

## Decision

**Hold for release evidence.** Local automated checks pass, but they do not
establish distribution readiness or completion of the September release.
No confirmed source defect was identified in this focused review.

Keep the September release separate from full MHUI adoption. The existing
MHDesign-only boundary, ADR 0008, and consumer checks agree with the brief.
Do not raise deployment targets or update packages to resolve an unproven
release concern.

## Reviewed Candidate

- Baseline: release tag `3.8`.
- Candidate: `120e9058` (`3.9` marketing version).
- Range: 59 commits and 222 changed files.
- Initial tracked and untracked working tree: clean.
- Scope: release-risk extraction, focused persistence/backup and identity
  review, library tests, app and Widgets builds, and limited live UI smoke.
- This is not an exhaustive review of every changed line.

## Automated Evidence

| Capability | Result | Limit |
| --- | --- | --- |
| Repository rules and SwiftLint | Pass | Static evidence |
| CookleLibrary tests | 274 passed, 0 failed/skipped | iOS 27 Simulator |
| Cookle build | Pass | Debug, Xcode 27 beta |
| Widgets build | Pass | Compile evidence, not Home Screen rendering |
| Watch compilation | Included in Cookle build | No shared Watch scheme or live Watch verification |
| App launch | Installed and running | Limited startup log observation only |
| UI capture | Tool-blocked, zero screenshots | No visual acceptance evidence |

Toolchain: Xcode 27.0, build `27A5252f`; iOS 27 Simulator. This is not proof
against the shipping toolchain or the oldest supported OS. The project keeps
its existing iOS 18 minimum deployment target.

The initial rules attempt failed because the sandbox denied a Swift module
cache write. The permitted rerun passed all checks. The app build reported
one Watch App Intents metadata warning because that target has no
AppIntents.framework dependency; it did not fail the build.

## Runtime And Visual Coverage

The limited iPhone attempt installed and launched Cookle. The runtime observer
reported startup readiness and a running process. Its console observation
included disabled notifications and an unpaired Watch session; these states
do not exercise notification delivery or Watch connectivity. The console
observation was returned through the integration, but no durable raw runtime
log file was exported.

The screenshot/hierarchy action returned `Session not found`. Separate
workspace discovery and an additional console query also stalled and were
interrupted. No screenshot was captured, so iPhone layout, settings,
iPad landscape, Watch UI, and Home Screen Widgets remain unverified. These
are tool coverage gaps, not observed app defects.

The verification-only app process was stopped. The device session endpoint
reported that the session no longer existed. The original selection was
restored and independently confirmed: `Cookle` scheme with
`iPhone 17 Pro for Fluel` destination. No simulator data was erased or seeded.

## Focused Risk Review

The built-in release-risk analyzer scored **75/100, Hold for review**, with
medium confidence. This is a heuristic triage score, not a confirmed defect
count or a probability of failure. Its highest category was capability and
configuration change, with additional durable-state and packaging signals.

| Signal | Inspected evidence | Assessment |
| --- | --- | --- |
| Model changes | Diary, Photo, PhotoObject, Category, Ingredient and IngredientObject diffs | Methods and error propagation changed; no stored-property change in these inspected diffs |
| External identity | Project settings and entitlement diff | Bundle identifiers retained; no entitlement diff |
| Backup replacement | Archive service and tests | Validation precedes deletion; save failure rolls back |
| Backup compatibility | Package round-trip and legacy JSON tests | Both pass; file-provider round trip remains separate |
| Ad configuration | SKAdNetwork, camera wording and privacy files | Review candidate only; actual SDK traffic and store answers not verified |
| MHUI boundary | Project products, ADR 0008 and static checks | Main app links MHDesign; full MHUI remains deferred |

Representative risky changes reviewed include:

```diff
- public static func create(context: ModelContext, photoData: PhotoData) -> Photo
+ public static func create(context: ModelContext, photoData: PhotoData) throws -> Photo
- MARKETING_VERSION = 3.8;
+ MARKETING_VERSION = 3.9;
```

The new photo creation path propagates fetch failures rather than treating
them as permission to insert a duplicate. The version change does not change
the bundle identity. Neither observation proves CloudKit upgrade behavior.

## Remaining Release Evidence

| Area | Required observation before closing the release |
| --- | --- |
| Distribution | Confirm shipping Xcode/Xcode Cloud configuration and archive result; confirm App Store Connect 3.9 state |
| Existing data and iCloud | Upgrade representative existing data, export/import through Files or iCloud Drive, then verify records/photos/relationships on two devices where practical |
| Subscription and ads | Exercise unknown, inactive, active and restored purchase states; verify ad suppression and actual AdMob behavior |
| Store privacy | Compare actual SDK behavior with App Store Connect answers; repository privacy text alone is insufficient |
| Notifications | Verify delivery and destination after relevant mutations and foreground/background transitions |
| Shortcuts | Execute representative recipe/diary actions through the system surface |
| Widgets | Verify actual timeline content and tap destinations on the Home Screen |
| Watch | Verify cooking steps, timers, connectivity and session end on a paired device |

Do not mark the release complete, create its release tag, or begin full MHUI
adoption from the local automated results alone.

## Full MHUI Adoption After Release

1. Confirm the September release is complete.
2. Capture a fresh baseline from current main and agree visual acceptance
   criteria for representative Cookle screens.
3. Approve the package visual direction and one small Cookle vertical slice.
4. Adopt the main app product together with an ADR superseding the app-target
   portion of ADR 0008, README/architecture updates, and consumer checks.
5. Verify package tests/rules, before-and-after visuals, native behavior,
   accessibility, size classes and appearance modes. Keep CookleLibrary,
   Widgets and Watch off presentation packages unless separately justified.

This sequence is retained as a conditional plan, not an approved visual design
or an instruction to begin the migration now.
