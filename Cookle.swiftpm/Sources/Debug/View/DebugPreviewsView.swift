//
//  DebugPreviewsView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI

struct DebugPreviewsView: View {
    var body: some View {
        List {
            StoreSection()
            AdvertisementSection(.medium)
            AdvertisementSection(.small)
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
