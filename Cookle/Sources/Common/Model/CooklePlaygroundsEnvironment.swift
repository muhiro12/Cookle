import SwiftUI
import GoogleMobileAdsWrapper
import StoreKitWrapper

extension View {
    func cooklePlaygroundsEnvironment() -> some View {
        environment(GoogleMobileAdsController(adUnitID: DemoAdUnitID.nativeAdvanced.rawValue))
            .environment(Store())
    }
}
