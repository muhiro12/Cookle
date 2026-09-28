import Foundation
import MHPlatform

enum CookleMonetizationConfiguration {
    // These production identifiers are public app configuration, not credentials.
    static let subscriptionProductID = "com.muhiro12.Cookle.subscriptions.monthly"
    static let subscriptionGroupID = "21496211"
    static let nativeAdUnitID = "ca-app-pub-2619807738023307/3246767710"
    static let nativeAdUnitIDDev = "ca-app-pub-3940256099942544/3986624511"

    /// Runs Google's consent flow before live ads start. DEBUG builds can
    /// simulate a regulated region by setting
    /// `COOKLE_ADS_CONSENT_DEBUG_GEOGRAPHY` to `eea`, `regulatedUSState`,
    /// or `other`.
    static var adsConsent: MHAdsConsentConfiguration {
        #if DEBUG
        .init(
            debugGeography: ProcessInfo.processInfo
                .environment["COOKLE_ADS_CONSENT_DEBUG_GEOGRAPHY"]
                .flatMap(MHAdsConsentConfiguration.DebugGeography.init(rawValue:))
        )
        #else
        .init()
        #endif
    }
}
