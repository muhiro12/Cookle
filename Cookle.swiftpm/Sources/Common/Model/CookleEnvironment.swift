import SwiftUI

extension View {
    public func cookleEnvironment(
        googleMobileAds: @escaping (String) -> some View,
        licenseList: @escaping () -> some View,
        storeKit: @escaping () -> some View
    ) -> some View {
        self.environment(GoogleMobileAdsPackage(builder: googleMobileAds))
            .environment(LicenseListPackage(builder: licenseList))
            .environment(StoreKitPackage(builder: storeKit))
    }

    func cooklePlaygroundsEnvironment() -> some View {
        cookleEnvironment(
            googleMobileAds: {
                Text("GoogleMobileAds \($0)")
            },
            licenseList: {
                Text("LicenseList")
            },
            storeKit: {
                Text("StoreKit")
            }
        )
    }
}
