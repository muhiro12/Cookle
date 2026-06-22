import Foundation
import MHPlatformCore

/// Library-owned catalog for primitive Cookle preference descriptors.
public enum CooklePreferenceCatalog {
    /// Returns primitive preference descriptors owned by the Cookle library.
    public static var primitiveDescriptors: [any MHStorageDescriptorProtocol] {
        let descriptors = MHPreferenceDescriptors()
        return [
            descriptors.isSubscribeOn,
            descriptors.isICloudOn,
            descriptors.isDebugOn,
            descriptors.isDailyRecipeSuggestionNotificationOn,
            descriptors.dailyRecipeSuggestionHour,
            descriptors.dailyRecipeSuggestionMinute,
            descriptors.tipExperienceVersion,
            descriptors.lastOpenedRecipeID,
            descriptors.lastLaunchedAppVersion,
            descriptors.activeCookingSessionSnapshot,
            descriptors.detachedObjectCleanupCompleted,
            descriptors.recipeBrowseSortSelection,
            descriptors.pendingIntentDeepLinkURL
        ]
    }
}
