import SwiftUI

extension View {
    public func cookleEnvironment(
        groupID: String,
        productID: String,
        googleMobileAds: @escaping (String) -> some View,
        licenseList: @escaping () -> some View
    ) -> some View {
        self.environment(\.groupID, groupID)
            .environment(\.productID, productID)
            .environment(GoogleMobileAdsPackage(builder: googleMobileAds))
            .environment(LicenseListPackage(builder: licenseList))
    }
    
    func cooklePlaygroundsEnvironment() -> some View {
        cookleEnvironment(
            groupID: "groupID",
            productID: "productID",
            googleMobileAds: {
                Text("GoogleMobileAds \($0)")
            },
            licenseList: {            
                Text("LicenseList")
            }
        )
    }
}
