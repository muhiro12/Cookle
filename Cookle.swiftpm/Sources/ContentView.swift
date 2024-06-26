//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI
import SwiftUtilities

public struct ContentView: View {
    @AppStorage(.isICloudOn) private var isICloudOn

    public init() {}

    public var body: some View {
        ModelContainerView()
            .id(isICloudOn)
    }
}

#Preview {
    CooklePreview { _ in
        ContentView()
    }
}
