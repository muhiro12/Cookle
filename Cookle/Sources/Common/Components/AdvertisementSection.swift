//
//  AdvertisementSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2022/01/17.
//

import MHAppRuntimeCore
import SwiftUI

struct AdvertisementSection {
    private enum Layout {
        static let sectionPadding = CGFloat(Int("8") ?? .zero)
    }

    enum Size: String {
        case small = "Small"
        case medium = "Medium"
    }

    @Environment(MHAppRuntime.self)
    private var appRuntime

    private let size: Size

    init(_ size: Size) {
        self.size = size
    }
}

extension AdvertisementSection: View {
    var body: some View {
        Section {
            appRuntime.nativeAdView(size: size.runtimeSize)
                .frame(maxWidth: .infinity)
                .padding(Layout.sectionPadding)
        }
    }
}

private extension AdvertisementSection.Size {
    var runtimeSize: MHNativeAdSize {
        switch self {
        case .small:
            .small
        case .medium:
            .medium
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    List {
        AdvertisementSection(.medium)
    }
}
