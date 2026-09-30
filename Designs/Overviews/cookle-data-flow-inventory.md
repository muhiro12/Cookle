# Cookle Data Flow Inventory

Source review updated September 26, 2026.

## Purpose

This note records, per data category, what Cookle holds, who receives it, why,
how long it is kept, and whether it leaves the device. It exists so that
disclosure reconciliation on
<https://github.com/muhiro12/Cookle/issues/75> can start from the code rather than
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

Stored by SwiftData in the app-group container shared by the iOS app and
widgets. The Watch app holds cooking-session snapshots delivered through
WatchConnectivity; it does not open this store. When the iCloud setting is on,
the same store is configured
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
on device. Apple's
[SystemLanguageModel documentation](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)
defines this type as the on-device model. Cookle does not select a
`PrivateCloudComputeLanguageModel`. `[source confirmed]` —
`Cookle/Sources/Features/Recipe/Services/RecipeFoundationModelInferenceOperations.swift`.

- **Recipient**: Apple's system model.
- **Leaves device**: no recipe text is sent off device by this inference path.

The deterministic fallback path used when the model is unavailable performs no
network access. `[source confirmed]`

### Image Playground

Presented through Apple's system generation UI. The app supplies a prompt and
receives an image. `[source confirmed]` —
`Cookle/Sources/Features/Recipe/Inference/CookleImagePlayground.swift`.

### Website import

`RecipeWebsiteReader` loads a URL the user typed or pasted into a `WKWebView`
whose configuration sets `websiteDataStore = .nonPersistent()`. WebKit keeps
this website data in memory instead of persisting it to disk; it can remain
available while the same reader and data store are reused.
`[source confirmed]` —
`Cookle/Sources/Features/Recipe/Services/RecipeWebsiteReader.swift`.

- **Recipient**: the chosen website and any resources it loads, which can
  observe their requests and the device IP address.
- **Retention**: website data is not persisted to disk by this data store.
  Imported text becomes editable form input; the form can retain a local draft
  and the user can save it as recipe content.
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
`UNUserNotificationCenter`. No app-owned call to
`registerForRemoteNotifications` was found. This does **not** establish that
push infrastructure is unused: SwiftData delegates synchronization to
`NSPersistentCloudKitContainer`, and Apple documents
[remote notifications as part of SwiftData sync](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices).
Cookle declares `aps-environment` and the `remote-notification` background mode.
Local reminders and framework-managed CloudKit notifications are separate
paths; push delivery has not been measured in this review.

### Diagnostics

`CookleAppLogging` writes through `MHLogger` to OSLog under the subsystem
`com.muhiro12.Cookle`. These entries stay in the device log store. `[source
confirmed]` — `Cookle/Sources/Platform/CookleAppLogging.swift`.

- **Leaves device**: no app-owned log upload is configured here. This source
  review does not establish every OS diagnostic collection or sharing path.

### Advertising

`AdvertisementSection` renders through MHPlatform's `MHNativeAdLayout`. The
AdMob application identifier and the SKAdNetwork list live in
`Cookle/Configurations/Info.plist`. `[source confirmed]` — the live runtime
sets `MHAppConfiguration.adsConsent`, placements require `canDisplayAds`, and
Settings offers Privacy Options when the consent SDK requires it. Cookle
requests no ATT authorization. `[delegated]` — MHPlatform owns the consent and
request lifecycle: after premium status resolves as inactive it refreshes
Google UMP consent each session, presents a form only when UMP requires one,
and starts the Google Mobile Ads SDK only when UMP allows ad requests. UMP
stores its consent state, including IAB TCF strings, in the standard defaults
domain, and preference cleanup keeps those keys.

Account-side Privacy & messaging configuration, regional applicability, and the
under-age tag policy are not established by this source review.

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

`CookleDataArchiveDocument` is a `FileDocument` exported through
`fileExporter`, to a destination the user picks. Its `.cookle` package
contains a JSON manifest and photo files, as specified in
[the export format](cookle-data-export-format.md). Only that format is
importable. `[source confirmed]` —
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

2. **Push configuration also serves CloudKit.** The absence of an app-owned
   registration call is not evidence that `aps-environment` is unused. Preserve
   the sync capability unless framework behavior is independently verified.

3. **There is no `NSPhotoLibraryUsageDescription`, and none is needed.** Photo
   selection goes through `PHPickerViewController`, which runs out of process
   and requires no library permission. The camera string is present and reads
   "Use the camera to take photos of your dishes or scan recipe text."
   `[source confirmed]`

4. **The Watch and widget privacy manifests declare user-defaults reasons only**
   (`CA92.1`/`1C8F.1` and `1C8F.1` respectively). The Widgets extension reads
   the shared store; the Watch
   receives snapshots through WatchConnectivity. Manifest contents alone do
   not prove that all required-reason API usage is covered. `[source confirmed]`

## 3) Published policy compared with this inventory

Compared September 22, 2026 against
`https://muhiro12.github.io/Cookle/privacy.html`, effective date 2026-09-16.
Statements below are about agreement between text and code. They are not legal
conclusions and they propose no wording.

### Statements the code supports

- Data is stored on device, and supported app data may also go to the user's
  iCloud account through CloudKit when sync is enabled.
- The developer operates no server receiving recipes, diary entries, photos or
  cooking data. App-owned networking also includes user-selected website
  imports, in addition to the remote-configuration and version GET requests.
  Framework and SDK traffic is listed separately above.
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
4. **Data export.** The marketing page advertises exporting recipes, diary and
   photos; the policy does not mention that the user can write that file to
   any destination they choose, including third-party storage.

### Framework claims checked against official contracts

- **"push notification infrastructure"** is compatible with framework-managed
  CloudKit synchronization. The absence of an app-owned remote-notification
  registration call does not contradict that disclosure.
- **"on-device language model"** matches the `SystemLanguageModel.default`
  selected by the recipe inference code. Private Cloud Compute is a separate
  model choice, not an automatic routing property of this type.

These correct the earlier inventory's contrary claims; they do not establish
runtime CloudKit delivery or make a legal determination about the policy.

### Links

All three resolve. `https://twitter.com/muhiro_12` redirects to the developer's
X account, and `https://www.apple.com/legal/privacy/` reaches Apple's customer
privacy policy. The third, labelled "Google AdMob privacy information", points
at `https://support.google.com/admob/answer/6128543`, which is **AdMob policies
and restrictions** — the publisher program policy, not information about what
AdMob collects.

## 4) What this note does not establish

Distribution territories, regional applicability, the AdMob and UMP consent
lifecycle, deletion and export claims measured against actual CloudKit
convergence, and subscription wording are all outside it. Those are the later
acceptance items on #75 and several of them need decisions or private
information that does not belong in a public document.
