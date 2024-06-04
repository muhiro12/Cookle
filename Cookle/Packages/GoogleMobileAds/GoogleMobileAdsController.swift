//
//  GoogleMobileAdsController.swift
//
//
//  Created by Hiromu Nakano on 2024/06/04.
//

import SwiftUI
import GoogleMobileAds

public struct GoogleMobileAdsController {
    private let adUnitID: String

    public init(adUnitID: String) {
        self.adUnitID = adUnitID

        Task {
            await GADMobileAds.sharedInstance().start()
        }
    }

    public func buildView(_ id: String) -> some View {
        NativeAdmob(
            adUnitID: adUnitID,
            sizeID: id
        )
    }
}
