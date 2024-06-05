//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI

public struct ContentView: View {
    @Environment(Secret.self) private var secret

    @AppStorage(.isICloudOn) private var isICloudOn

    private var sharedStore = Store()

    public init() {}

    public var body: some View {
        ModelContainerView()
            .task {
                sharedStore.open(
                    groupID: secret.groupID,
                    productIDs: [secret.productID]
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
