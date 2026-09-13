//
//  AdvertisementSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2022/01/17.
//

import MHDesign
import MHPlatform
import SwiftUI

struct AdvertisementSection {
    @Environment(\.mhDesignMetrics)
    private var designMetrics
    @Environment(MHAppRuntime.self)
    private var appRuntime

    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn

    private let size: MHNativeAdSize

    init(_ size: MHNativeAdSize) {
        self.size = size
    }
}

extension AdvertisementSection: View {
    var body: some View {
        if !isSubscribeOn, appRuntime.adsAvailability == .available {
            Section {
                appRuntime.nativeAdView(size: size)
                    .frame(maxWidth: .infinity)
                    .padding(designMetrics.spacing.inline)
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    List {
        AdvertisementSection(.medium)
    }
}

#Preview("Ads not configured") {
    List {
        Text(verbatim: "Content before ad")
        AdvertisementSection(.medium)
        Text(verbatim: "Content after ad")
    }
    .environment(MHAppRuntime(runtimeOnly: .init()))
}
