//
//  CookleEnvironment.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/8/24.
//

import SwiftUI

public extension View {
    func cookleEnvironment(
        googleMobileAds: @escaping (String) -> some View,
        licenseList: @escaping () -> some View,
        storeKit: @escaping () -> some View
    ) -> some View {
        self.environment(GoogleMobileAdsPackage(builder: googleMobileAds))
            .environment(LicenseListPackage(builder: licenseList))
            .environment(StoreKitPackage(builder: storeKit))
    }
}
