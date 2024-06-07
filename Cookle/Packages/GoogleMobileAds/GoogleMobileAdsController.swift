//
//  GoogleMobileAdsController.swift
//
//
//  Created by Hiromu Nakano on 2024/06/07.
//

import SwiftUI
import GoogleMobileAdsWrapper

public struct GoogleMobileAdsController {
    private let controller: GoogleMobileAdsWrapper.GoogleMobileAdsController

    public init(adUnitID: String) {
        controller = .init(adUnitID: adUnitID)
    }

    public func buildView(_ id: String) -> some View {
        controller.buildView(id)
    }
}
