//
//  DebugPreviewsView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI
import StoreKitWrapper

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

#Preview {
    CooklePreview { _ in
        NavigationStack {
            DebugPreviewsView()
        }
    }
}
