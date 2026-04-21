import Foundation
import MHPlatformCore

/// App-owned preference descriptors used by Cookle targets.
public extension MHPreferenceDescriptors {
    /// Subscription entitlement mirror stored in the standard app domain.
    var isSubscribeOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.isSubscribeOn.rawValue,
            defaultSelection: .standard,
            default: false
        )
    }

    /// Current iCloud sync toggle stored in the standard app domain.
    var isICloudOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.isICloudOn.rawValue,
            defaultSelection: .standard,
            default: false
        )
    }

    /// Debug feature toggle stored in the standard app domain.
    var isDebugOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.isDebugOn.rawValue,
            defaultSelection: .standard,
            default: false
        )
    }

    /// Daily recipe suggestion notification enablement.
    var isDailyRecipeSuggestionNotificationOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.isDailyRecipeSuggestionNotificationOn.rawValue,
            defaultSelection: .standard,
            default: false
        )
    }

    /// Preferred hour for daily recipe suggestion notifications.
    var dailyRecipeSuggestionHour: MHIntPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.dailyRecipeSuggestionHour.rawValue,
            defaultSelection: .standard,
            default: .zero
        )
    }

    /// Preferred minute for daily recipe suggestion notifications.
    var dailyRecipeSuggestionMinute: MHIntPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.dailyRecipeSuggestionMinute.rawValue,
            defaultSelection: .standard,
            default: .zero
        )
    }

    /// TipKit experience version marker.
    var tipExperienceVersion: MHIntPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.tipExperienceVersion.rawValue,
            defaultSelection: .standard,
            default: .zero
        )
    }

    /// Last opened recipe identifier shared with widgets and intents.
    var lastOpenedRecipeID: MHStringPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.AppGroup.lastOpenedRecipeID.rawValue,
            defaultSelection: .suite(UserDefaults.appGroupIdentifier)
        )
    }

    /// Last launched app version stored in the standard app domain.
    var lastLaunchedAppVersion: MHStringPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.lastLaunchedAppVersion.rawValue,
            defaultSelection: .standard
        )
    }

    /// Active cooking session snapshot stored in the standard app domain.
    var activeCookingSessionSnapshot: MHStringPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.activeCookingSessionSnapshot.rawValue,
            defaultSelection: .standard
        )
    }

    /// One-time maintenance flag for detached parent-owned object cleanup.
    var detachedObjectCleanupCompleted: MHBoolPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.Standard.detachedObjectCleanupCompleted.rawValue,
            defaultSelection: .standard,
            default: false
        )
    }

    /// Pending deep link handoff shared across app targets.
    var pendingIntentDeepLinkURL: MHStringPreferenceDescriptor {
        .init(
            storageKey: CookleUserDefaultsKeys.AppGroup.pendingIntentDeepLinkURL.rawValue,
            defaultSelection: .suite(UserDefaults.appGroupIdentifier)
        )
    }
}
