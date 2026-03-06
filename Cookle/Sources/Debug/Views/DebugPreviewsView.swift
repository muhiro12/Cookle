//
//  DebugPreviewsView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import MHPlatform
import SwiftUI

struct DebugPreviewsView: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    var body: some View {
        List {
            appRuntime.subscriptionSectionView()
            AdvertisementSection(.medium)
            AdvertisementSection(.small)
            ShortcutsLinkSection()
        }
        .navigationTitle(Text("Previews"))
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        DebugPreviewsView()
    }
}
