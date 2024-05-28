//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI

public struct ContentView: View {
    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

    public init() {
        #if DEBUG
        isDebugOn = true
        #endif
    }

    public var body: some View {
        ModelContainerView()
            .id(isICloudOn)
    }
}

#Preview {
    ContentView()
}
