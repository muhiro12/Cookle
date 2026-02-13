//
//  DebugPreviewsView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import StoreKitWrapper
import SwiftUI

struct DebugPreviewsView: View {
    @Environment(Store.self) private var store

    var body: some View {
        List {
            store.buildSubscriptionSection()
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
