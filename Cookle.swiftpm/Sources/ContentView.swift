//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI

public struct ContentView: View {
    @Environment(\.groupID) private var groupID
    @Environment(\.productID) private var productID

    @AppStorage(.isICloudOn) private var isICloudOn

    private var sharedStore = Store()

    public init() {}

    public var body: some View {
        ModelContainerView()
            .task {
                sharedStore.open(
                    groupID: groupID,
                    productIDs: [productID]
                )
            }
            .environment(sharedStore)
            .id(isICloudOn)
    }
}

#Preview {
    CooklePreview { _ in
        ContentView()
    }
}
