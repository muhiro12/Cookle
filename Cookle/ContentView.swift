//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI

struct ContentView: View {
    init() {}

    var body: some View {
        MainView()
            .onAppear {
                Logger(#file).info("ContentView appeared")
            }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    ContentView()
}
