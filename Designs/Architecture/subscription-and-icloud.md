# Subscription and iCloud

## Saved choice, access, and current configuration

Cookle adopts the next-process-launch boundary proposed in
[#169](https://github.com/muhiro12/Cookle/issues/169#issuecomment-6858779506),
using [Incomes' implementation](https://github.com/muhiro12/Incomes/blob/cc822199caf391f02e33525d23b36e1d8508fb99/Designs/Architecture/subscription-and-icloud.md)
as a reference. Immediate store reassembly is no longer a requirement.

`ICloudSyncOperations` keeps the existing preference contracts:

- Resolved active/inactive access updates `isSubscribeOn` only. Unknown access
  preserves the last resolved value.
- `isICloudOn` is the saved choice. Purchase, restore, lapse, and renewal do not
  change it. First purchase does not enable sync without an explicit choice.
- `isEnabledAtNextLaunch` combines both values. Startup uses that result with
  the existing production store URL and CloudKit `.automatic` or `.none`.
  DEBUG continues using the separate local development store.

`CookleAppBootstrapModel` selects the configuration before opening the store.
A ready assembly stays installed for the process lifetime. Preference changes,
subscription updates, editor dismissal, and background resume do not rebuild it.
The preference path does not delete, copy, reset, or replace stored records.
App Intent dependencies continue resolving the ready assembly even when the
next-launch choice differs from its configuration.

Startup uses cached resolved access without waiting for a network entitlement
check. An access result received after the store opens changes only the next
launch decision. Recognizing purchase, restore, or expiry after startup can
therefore require another launch before the corresponding sync change applies.
Existing records are not gated on that network check.

## Settings and current-session behavior

MHPlatform's standard entitlement propagation remains the source of runtime
access. Non-storage paid UI, ads, and purchase navigation remain responsive
within the current session. Purchase navigation is tracked in #168.

The Release iCloud section remains accessible without a subscription. A retained
On choice can be turned Off during a lapse; Off cannot become On without access.
The toggle is the saved choice, while separate text describes the actual open
container. Direction-specific notices explain pending enablement or disablement
and that returning from the background does not apply it. Reversing a pending
choice removes the notice when it again matches the current configuration.

Off or confirmed inactive access does not immediately stop sync in an already
cloud-configured session. A retained On without access does not enable sync at
the next launch. Account guidance follows the current configuration, including
when a change to Off is pending. Configuration and account availability do not
establish completed delivery, remote convergence, or a guarantee against loss.

## Recovery and retained safeguards

`retryStartup()` only opens after startup failure, before any ready assembly
exists, and rejects overlapping retries. Opening without iCloud explicitly saves
Off and retries that failed startup. Serialized opens and cancellation checking
remain. A setting changed during an in-flight open does not start another open;
the completed configuration is retained and Settings explains any difference.

Retired-container mutation rejection and clean-context checks remain available.
There is no automatic live swap, manual Apply now action, or process termination
button. Editor-registration deferral is unnecessary with a fixed container and
has been removed.

Reconsider live replacement only in a separate investigation that establishes a
supported sync-stack shutdown/handoff, drains outstanding operations, rejects
stale writes, and qualifies pending-edit and failure recovery. The current
choice does not assert that all same-process designs are impossible or that a
Cookle data-loss incident has been reproduced.

## Verification boundary

Shared production-policy tests cover both saved choices across lapse/renewal,
all unknown-state combinations, first purchase without opt-in, explicit Off
during a lapse, cancellation of pending choice changes, and reading the decision
from reopened preference stores. They do not simulate StoreKit or CloudKit.

The 2026-11-14 Xcode-native verification reported all 759 ordinary test results
and both synthetic schema-research observations passing. The latter still
characterize the existing future-schema downgrade limitation; they do not
establish data-loss safety.
The Debug app build and unsigned Release Simulator build passed. A native code
snippet confirmed that retry and repeated startup preserve a ready assembly,
container identity, and Settings navigation in the isolated development store.

All three Japanese section previews rendered on iPhone 18 Pro / iOS 27.2:
lapsed access with a cloud-configured session, renewed access with pending
activation, and inactive access with explicit Off. These are direct Preview
captures, not full Settings interaction or entitlement-delivery evidence.
The eight new messages cover all five app languages; four retired live-switch
messages were removed after checking references.

The native test builds emitted an SDK sysroot warning. A CLI rerun of the full
ordinary plan reported 640 passing Swift Testing tests without that warning,
but emitted one App Intents metadata extraction warning for the schema-research
test product built alongside the plan. The zero-raw-warning gate remains
unqualified. The initial Release build also emitted two missing-debug-symbol
warnings from the LicenseList build tool; the final incremental Release build
reported zero warnings and errors. No warning suppression or project-setting
workaround was added. Retained lint and repository checks passed.

Real purchase/restore and transient verification, Release settings interaction,
account/offline behavior, startup-failure recovery on actual stores, and isolated
two-device CloudKit convergence remain qualification work in #169. A successful
build or a local-store check does not establish those outcomes.
