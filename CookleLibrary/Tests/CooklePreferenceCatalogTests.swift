@testable import CookleLibrary
import Foundation
import MHPlatformCore
import Testing

struct CooklePreferenceCatalogTests {
    @Test
    func storageKeys_areOpaqueAndUnique() {
        let storageKeys = CookleUserDefaultsKeys.allStorageKeys

        #expect(storageKeys.isEmpty == false)
        #expect(Set(storageKeys).count == storageKeys.count)

        for storageKey in storageKeys {
            #expect(
                storageKey.range(
                    of: "^[A-Za-z0-9]{8}$",
                    options: .regularExpression
                ) != nil
            )
        }
    }

    @Test
    func primitiveDescriptorCatalog_usesExpectedStorageKeys() {
        let primitiveDescriptorKeys = CooklePreferenceCatalog.primitiveDescriptors.map(\.storageKey)
        let descriptors = MHPreferenceDescriptors()
        let expectedKeys = [
            descriptors.isSubscribeOn.storageKey,
            descriptors.isICloudOn.storageKey,
            descriptors.isDebugOn.storageKey,
            descriptors.isDailyRecipeSuggestionNotificationOn.storageKey,
            descriptors.dailyRecipeSuggestionHour.storageKey,
            descriptors.dailyRecipeSuggestionMinute.storageKey,
            descriptors.tipExperienceVersion.storageKey,
            descriptors.lastOpenedRecipeID.storageKey,
            descriptors.lastLaunchedAppVersion.storageKey,
            descriptors.pendingIntentDeepLinkURL.storageKey
        ]

        #expect(Set(primitiveDescriptorKeys) == Set(expectedKeys))
        #expect(Set(primitiveDescriptorKeys).isSubset(of: Set(CookleUserDefaultsKeys.allStorageKeys)))
    }

    @Test
    func primitiveDescriptors_keepExpectedDefaultSelections() {
        let descriptors = MHPreferenceDescriptors()

        #expect(descriptors.isSubscribeOn.defaultSelection == .standard)
        #expect(descriptors.isICloudOn.defaultSelection == .standard)
        #expect(descriptors.isDebugOn.defaultSelection == .standard)
        #expect(descriptors.isDailyRecipeSuggestionNotificationOn.defaultSelection == .standard)
        #expect(descriptors.dailyRecipeSuggestionHour.defaultSelection == .standard)
        #expect(descriptors.dailyRecipeSuggestionMinute.defaultSelection == .standard)
        #expect(descriptors.tipExperienceVersion.defaultSelection == .standard)
        #expect(descriptors.lastLaunchedAppVersion.defaultSelection == .standard)
        #expect(
            descriptors.lastOpenedRecipeID.defaultSelection
                == .suite(CookleSharedPreferences.appGroupIdentifier)
        )
        #expect(
            descriptors.pendingIntentDeepLinkURL.defaultSelection
                == .suite(CookleSharedPreferences.appGroupIdentifier)
        )
    }
}
