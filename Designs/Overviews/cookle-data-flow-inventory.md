# Cookle Data Flow Inventory

Current behavior as of September 21, 2026.

## Purpose

This note records, per data category, what Cookle holds, who receives it, why,
how long it is kept, and whether it leaves the device. It exists so that
disclosure reconciliation on
https://github.com/muhiro12/Cookle/issues/75 can start from the code rather than
re-derive it, and so that a later change to any of these paths has something to
be compared against.

It is a description of current behavior. It states no legal conclusion, asserts
no regional applicability, and selects no remedy. Where the code and a published
disclosure could disagree, this note says what the code does and stops there.

Evidence labels:

- `[source confirmed]`: read directly from app, package, or bundle configuration
- `[delegated]`: the runtime contract belongs to a dependency, named inline

## 1) Inventory

### Recipes, diary entries, ingredients, categories

Stored by SwiftData in the app-group container shared by the app, the Watch app,
and the widgets. When the iCloud setting is on, the same store is configured
with `cloudKitDatabase: .automatic` and synchronizes through the user's own
CloudKit private database under `iCloud.com.muhiro12.Cookle`; when it is off,
`.none` is used and nothing is sent. `[source confirmed]` —
`Cookle/Sources/Platform/CookleAppBootstrapModel.swift`,
`Cookle/Configurations/Cookle.entitlements`.

- **Recipient**: Apple (CloudKit), only when the setting is on.
- **Purpose**: the user's own sync between their devices.
- **Retention**: until the user deletes the record, or the store.
- **Leaves device**: yes, conditionally, to the user's own private database.

### Photos

Photo bytes are stored as binary in that same store, so they follow the same
path and the same condition. Diary notes and recipe notes are likewise ordinary
stored properties. `[source confirmed]`

### Photo text recognition

`TextRecognitionService` uses Vision's `VNRecognizeTextRequest` with a
`VNImageRequestHandler` built from the image already in memory. There is no
network call on this path. `[source confirmed]` —
`Cookle/Sources/Features/Recipe/Inference/TextRecognitionService.swift`.

- **Recipient**: none.
- **Leaves device**: no.

### Recipe inference

`RecipeFoundationModelInferenceOperations` uses `SystemLanguageModel.default`
and `LanguageModelSession`. The app passes recipe text to Apple's system model
and does not select where that model runs; routing between on-device and Private
Cloud Compute is Apple's, not Cookle's. `[source confirmed]` —
`Cookle/Sources/Features/Recipe/Services/RecipeFoundationModelInferenceOperations.swift`.

- **Recipient**: Apple's system model.
- **Leaves device**: determined by Apple's routing, not by this app.

The deterministic fallback path used when the model is unavailable performs no
network access. `[source confirmed]`

### Image Playground

Presented through Apple's system generation UI. The app supplies a prompt and
receives an image. `[source confirmed]` —
`Cookle/Sources/Features/Recipe/Inference/CookleImagePlayground.swift`.

### Website import

`RecipeWebsiteReader` loads a URL the user typed or pasted into a `WKWebView`
whose configuration sets `websiteDataStore = .nonPersistent()`, so no cookies or
website data are retained between imports. `[source confirmed]` —
`Cookle/Sources/Features/Recipe/Services/RecipeWebsiteReader.swift`.

- **Recipient**: whichever site the user chose, which necessarily observes the
  request and the device IP address.
- **Retention**: none in the app; the page text becomes a draft only if the user
  imports it.
- **Leaves device**: yes — the request itself, by definition.

### Remote configuration and version lookup

Two unauthenticated GET requests, neither carrying user content:

- `https://raw.githubusercontent.com/muhiro12/Cookle/main/.config.json`
- `https://itunes.apple.com/lookup?id=6483363226&country=jp`

`[source confirmed]` — `Cookle/Sources/Features/RemoteConfiguration/`.

- **Recipient**: GitHub and Apple, which observe the device IP address.
- **Leaves device**: the request; no app data.

### Notifications

`NotificationService` schedules local notifications through
`UNUserNotificationCenter`. **Nothing in the app, the Watch app, or the widgets
calls `registerForRemoteNotifications`**, so no device token is created and no
push service is contacted. `[source confirmed]`

### Diagnostics

`CookleAppLogging` writes through `MHLogger` to OSLog under the subsystem
`com.muhiro12.Cookle`. These entries stay in the device log store. `[source
confirmed]` — `Cookle/Sources/Platform/CookleAppLogging.swift`.

- **Leaves device**: only if the user themselves exports a sysdiagnose.

### Advertising

`AdvertisementSection` renders through MHPlatform's `MHNativeAdSize`. The
AdMob application identifier and the SKAdNetwork list live in
`Cookle/Configurations/Info.plist`. `[delegated]` — the consent and request
lifecycle is MHPlatform's contract, tracked on muhiro12/MHPlatform#14, and is
deliberately not restated here.

### Subscriptions

Product and group identifiers come from `CookleMonetizationConfiguration` and
are handed to the MHPlatform runtime, which owns the StoreKit interaction.
`[delegated]` — `Cookle/Sources/Platform/CookleAppAssemblyFactory.swift`.

### Preferences

`MHPreferenceStore` writes to the standard and app-group `UserDefaults` domains
for `com.muhiro12.Cookle` and `group.com.muhiro12.Cookle`. This includes the
unsaved recipe-form draft. `[source confirmed]`

- **Leaves device**: no, except as part of a device backup the user makes.

### User-initiated export

`CookleDataArchiveDocument` is a `FileDocument` exported as JSON through
`fileExporter`, to a destination the user picks. `[source confirmed]` —
`Cookle/Sources/Features/Settings/`.

## 2) Observations for reconciliation

These are factual mismatches between configuration and code. Each is a question
for the disclosure work, not a defect claim.

1. **The app's privacy manifest declares no collected data types and no tracking
   domains.** `Cookle/Resources/PrivacyInfo.xcprivacy` contains only
   `NSPrivacyAccessedAPITypes` — file timestamp (`C617.1`) and user defaults
   (`CA92.1`, `1C8F.1`). Meanwhile the bundle carries a `GADApplicationIdentifier`
   and 50 `SKAdNetworkIdentifier` entries. Whether the SDK's own manifest is
   intended to cover that, and whether the app-level answers agree, is exactly
   what the second acceptance item on #75 asks to compare. `[source confirmed]`

2. **`aps-environment` is present in the entitlements but unused.** No code path
   registers for remote notifications, so the capability is declared and not
   exercised. `[source confirmed]`

3. **There is no `NSPhotoLibraryUsageDescription`, and none is needed.** Photo
   selection goes through `PHPickerViewController`, which runs out of process
   and requires no library permission. The camera string is present and reads
   "Use the camera to take photos of your dishes or scan recipe text."
   `[source confirmed]`

4. **The Watch and widget privacy manifests declare user-defaults reasons only**
   (`CA92.1`/`1C8F.1` and `1C8F.1` respectively), which matches their observed
   behavior of reading the shared store and preferences. `[source confirmed]`

## 3) Published policy compared with this inventory

Compared September 22, 2026 against
`https://muhiro12.github.io/Cookle/privacy.html`, effective date 2026-09-16.
Statements below are about agreement between text and code. They are not legal
conclusions and they propose no wording.

### Statements the code supports

- Data is stored on device, and supported app data may also go to the user's
  iCloud account through CloudKit when sync is enabled.
- The developer operates no server receiving recipes, diary entries, photos or
  cooking data. The only outbound requests the app makes itself are the two
  unauthenticated GETs in section 1.
- No precise location data. There is no `CoreLocation` use in any target.
- A nonpersistent web browsing data store is used for website import. This
  matches `websiteDataStore = .nonPersistent()` exactly.
- Apple's language model is used with no developer-operated AI server.
- Network access for remote configuration, including a version check.
- The source address is included in the editable recipe note.
- Images from the source website are not automatically attached. The reader
  extracts no images.

### Data paths present in code and absent from the policy

1. **Image Playground.** `CookleImagePlaygroundModifier` presents
   `.imagePlaygroundSheet`, and generated images are stored as recipe photos
   carrying `PhotoSource.imagePlayground`. Image generation is not mentioned.
2. **Photo text recognition.** `TextRecognitionService` runs Vision over photos
   the user supplies. The policy discusses extracted recipe text only in the
   website-import context.
3. **Camera.** `NSCameraUsageDescription` is declared — "Use the camera to take
   photos of your dishes or scan recipe text" — and the camera is not described
   as a data source.
4. **Backup export.** The marketing page advertises exporting recipes, diary and
   photos; the policy does not mention that the user can write that archive to
   any destination they choose, including third-party storage.

### A statement stronger than the code

5. **"push notification infrastructure"** appears in the list of Apple services
   used. Nothing in any target registers for remote notifications; every
   notification is local. `aps-environment` is declared in the entitlements and
   unexercised, so this describes a flow that does not occur.
6. **"on-device language model"** is more specific than the code guarantees.
   `SystemLanguageModel.default` routes between on-device execution and Private
   Cloud Compute at Apple's discretion; the app does not choose.

### Links

All three resolve. `https://twitter.com/muhiro_12` redirects to the developer's
X account, and `https://www.apple.com/legal/privacy/` reaches Apple's customer
privacy policy. The third, labelled "Google AdMob privacy information", points
at `https://support.google.com/admob/answer/6128543`, which is **AdMob policies
and restrictions** — the publisher program policy, not information about what
AdMob collects.

## 3) What this note does not establish

Distribution territories, regional applicability, the AdMob and UMP consent
lifecycle, deletion and export claims measured against actual CloudKit
convergence, and subscription wording are all outside it. Those are the later
acceptance items on #75 and several of them need decisions or private
information that does not belong in a public document.
