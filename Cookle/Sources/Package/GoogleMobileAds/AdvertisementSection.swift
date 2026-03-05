//
//  AdvertisementSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2022/01/17.
//

import GoogleMobileAdsWrapper
import SwiftUI

struct AdvertisementSection {
    private enum Layout {
        static let sectionPadding = CGFloat(Int("8") ?? .zero)
    }

    enum Size: String {
        case small = "Small"
        case medium = "Medium"
    }

    @Environment(GoogleMobileAdsController.self)
    private var googleMobileAdsController

    private let size: Size

    init(_ size: Size) {
        self.size = size
    }
}

extension AdvertisementSection: View {
    var body: some View {
        Section {
            googleMobileAdsController.buildNativeAd(size.rawValue)
                .frame(maxWidth: .infinity)
                .padding(Layout.sectionPadding)
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    List {
        AdvertisementSection(.medium)
    }
}
