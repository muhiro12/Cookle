//
//  StoreSection.swift
//
//
//  Created by Hiromu Nakano on 2024/06/05.
//

import StoreKit
import SwiftUI

struct StoreSection: View {
    @Environment(Store.self)
    private var store

    var body: some View {
        Section {
            SubscriptionStoreView(groupID: store.groupID)
                .storeButton(.visible, for: .policies)
                .storeButton(.visible, for: .restorePurchases)
                .storeButton(.hidden, for: .cancellation)
                .subscriptionStorePolicyDestination(
                    url: .init(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
                    for: .termsOfService
                )
                .fixedSize(horizontal: false, vertical: true)
        } footer: {
            Text(store.product?.description ?? "")
        }
    }
}

#Preview {
    CooklePreview { _ in
        List {
            StoreSection()
        }
    }
}
