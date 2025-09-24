//
//  MainView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/27.
//

import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @Environment(ConfigurationService.self) private var configurationService

    @State private var isUpdateAlertPresented = false

    var body: some View {
        MainTabView()
            .alert(Text("Update Required"), isPresented: $isUpdateAlertPresented) {
                Button {
                    UIApplication.shared.open(
                        .init(string: "https://apps.apple.com/app/id6483363226")!
                    )
                } label: {
                    Text("Open App Store")
                }
            } message: {
                Text("Please update Cookle to the latest version to continue using it.")
            }
            .task {
                try? await configurationService.load()
                isUpdateAlertPresented = configurationService.isUpdateRequired()
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else {
                    return
                }
                Task {
                    try? await configurationService.load()
                    isUpdateAlertPresented = configurationService.isUpdateRequired()
                }
                if Int.random(in: 0..<10) == .zero {
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        requestReview()
                    }
                }
            }
    }
}

#Preview {
    CooklePreview { _ in
        MainView()
    }
}
