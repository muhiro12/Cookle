//
//  AdvertisementSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2022/01/17.
//

import MHPlatform
import MHUI
import SwiftUI

struct AdvertisementSection {
    @Environment(\.mhDesignMetrics)
    private var designMetrics
    @Environment(MHAppRuntime.self)
    private var appRuntime

    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn

    private let layout: MHNativeAdLayout

    init(_ layout: MHNativeAdLayout) {
        self.layout = layout
    }
}

extension AdvertisementSection: View {
    var body: some View {
        if !isSubscribeOn, appRuntime.canDisplayAds {
            Section {
                appRuntime.nativeAdView(layout: layout)
                    .frame(maxWidth: .infinity)
                    .padding(designMetrics.spacing.inline)
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    List {
        AdvertisementSection(.media)
    }
}

#Preview("Ads not configured") {
    List {
        Text(verbatim: "Content before ad")
        AdvertisementSection(.media)
        Text(verbatim: "Content after ad")
    }
    .environment(MHAppRuntime(runtimeOnly: .init()))
}
