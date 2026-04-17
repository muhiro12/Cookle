//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2026/04/18.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
