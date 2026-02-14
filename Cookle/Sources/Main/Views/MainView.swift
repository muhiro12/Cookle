//
//  MainView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/27.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @Environment(ConfigurationService.self) private var configurationService

    @State private var hasLoaded = false
    @State private var isIntroductionPresented = false
    @State private var isUpdateAlertPresented = false
    @State private var selectedTab = MainTab.diary

    var body: some View {
        MainTabView(selection: $selectedTab)
            .sheet(isPresented: $isIntroductionPresented) {
                IntroductionNavigationView()
            }
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
                if !hasLoaded {
                    hasLoaded = true
                    isIntroductionPresented = shouldPresentIntroduction()
                }
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
            .onOpenURL { deepLinkURL in
                guard let destination = CookleWidgetDeepLink.destination(from: deepLinkURL) else {
                    return
                }
                selectedTab = tab(for: destination)
            }
    }
}

private extension MainView {
    func tab(for destination: CookleWidgetDestination) -> MainTab {
        switch destination {
        case .diary:
            return .diary
        case .recipe:
            return .recipe
        }
    }

    func shouldPresentIntroduction() -> Bool {
        do {
            let recipeCount = try context.fetchCount(
                FetchDescriptor<Recipe>()
            )
            return recipeCount.isZero
        } catch {
            assertionFailure(error.localizedDescription)
            return false
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    MainView()
}
