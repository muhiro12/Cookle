import Foundation
import MHPlatformCore

public extension MHPreferenceDescriptors {
    var isSubscribeOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: "qWeRty12",
            defaultSelection: .standard,
            default: false
        )
    }

    var isICloudOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: "AO9Yo1cC",
            defaultSelection: .standard,
            default: false
        )
    }

    var isDebugOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: "hd3fAy3G",
            defaultSelection: .standard,
            default: false
        )
    }

    var isDailyRecipeSuggestionNotificationOn: MHBoolPreferenceDescriptor {
        .init(
            storageKey: "m9Pq2Ls4",
            defaultSelection: .standard,
            default: false
        )
    }

    var dailyRecipeSuggestionHour: MHIntPreferenceDescriptor {
        .init(
            storageKey: "r5Vn8Kt1",
            defaultSelection: .standard,
            default: .zero
        )
    }

    var dailyRecipeSuggestionMinute: MHIntPreferenceDescriptor {
        .init(
            storageKey: "u7Bx3Jd6",
            defaultSelection: .standard,
            default: .zero
        )
    }

    var tipExperienceVersion: MHIntPreferenceDescriptor {
        .init(
            storageKey: "t7Px9Nb4",
            defaultSelection: .standard,
            default: .zero
        )
    }

    var lastOpenedRecipeID: MHStringPreferenceDescriptor {
        .init(
            storageKey: "zxcXvb12",
            defaultSelection: .suite(UserDefaults.appGroupIdentifier)
        )
    }

    var lastLaunchedAppVersion: MHStringPreferenceDescriptor {
        .init(
            storageKey: "s9Kp4Ld2",
            defaultSelection: .standard
        )
    }

    var pendingIntentDeepLinkURL: MHStringPreferenceDescriptor {
        .init(
            storageKey: "L2nV8qRs",
            defaultSelection: .suite(UserDefaults.appGroupIdentifier)
        )
    }
}
