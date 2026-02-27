//
//  MainView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/27.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview
    @Environment(ConfigurationService.self) private var configurationService

    @State private var isUpdateAlertPresented = false
    @State private var selectedTab = MainTab.diary
    @State private var pendingRoute: CookleRoute?
    @State private var selectedDiary: Diary?
    @State private var selectedDiaryRecipe: Recipe?
    @State private var selectedRecipe: Recipe?
    @State private var selectedSearchRecipe: Recipe?
    @State private var incomingSearchQuery: String?
    @State private var incomingSettingsSelection: SettingsContent?
    @State private var compactSettingsSelection: SettingsContent?
    @State private var isCompactSettingsPresented = false

    var body: some View {
        MainTabView(
            selection: $selectedTab,
            diarySelection: $selectedDiary,
            diaryRecipeSelection: $selectedDiaryRecipe,
            recipeSelection: $selectedRecipe,
            searchSelection: $selectedSearchRecipe,
            incomingSearchQuery: $incomingSearchQuery,
            incomingSettingsSelection: $incomingSettingsSelection
        )
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
            applyPendingIntentRouteIfNeeded()
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
            applyPendingIntentRouteIfNeeded()
        }
        .onOpenURL { deepLinkURL in
            handleIncomingURL(deepLinkURL)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard let webpageURL = userActivity.webpageURL else {
                return
            }
            handleIncomingURL(webpageURL)
        }
        .sheet(
            isPresented: $isCompactSettingsPresented,
            onDismiss: {
                compactSettingsSelection = nil
            }
        ) {
            SettingsNavigationView(
                incomingSelection: $compactSettingsSelection
            )
        }
    }
}

private extension MainView {
    func applyPendingIntentRouteIfNeeded() {
        guard let intentRouteURL = CookleIntentRouteStore.consume() else {
            return
        }
        handleIncomingURL(intentRouteURL)
    }

    func handleIncomingURL(_ url: URL) {
        guard let route = CookleRouteParser.parse(url: url) else {
            return
        }
        pendingRoute = route
        Task { @MainActor in
            applyPendingRouteIfNeeded()
        }
    }

    func applyPendingRouteIfNeeded() {
        guard let pendingRoute else {
            return
        }
        self.pendingRoute = nil
        do {
            let outcome = try CookleRouteExecutor.execute(
                route: pendingRoute,
                context: context
            )
            applyRouteOutcome(outcome)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func applyRouteOutcome(_ outcome: CookleRouteOutcome) {
        if outcome.isSettingsRoute == false {
            isCompactSettingsPresented = false
            compactSettingsSelection = nil
        }

        switch outcome {
        case .home:
            selectedTab = .diary
            selectedDiary = nil
            selectedDiaryRecipe = nil
            selectedRecipe = nil
            selectedSearchRecipe = nil
            incomingSearchQuery = nil
        case .diary(let diary):
            selectedTab = .diary
            selectedDiary = diary
            selectedDiaryRecipe = nil
        case .recipe(let recipe):
            selectedTab = .recipe
            selectedRecipe = recipe
        case .search(let query):
            selectedTab = .search
            selectedSearchRecipe = nil
            incomingSearchQuery = query
        case .settings:
            applySettingsRoute(destination: nil)
        case .settingsSubscription:
            applySettingsRoute(destination: .subscription)
        case .settingsLicense:
            applySettingsRoute(destination: .license)
        }
    }

    func applySettingsRoute(destination: SettingsContent?) {
        if horizontalSizeClass == .regular {
            isCompactSettingsPresented = false
            compactSettingsSelection = nil
            selectedTab = .settings
            incomingSettingsSelection = destination
        } else {
            compactSettingsSelection = destination
            isCompactSettingsPresented = true
        }
    }
}

private extension CookleRouteOutcome {
    var isSettingsRoute: Bool {
        switch self {
        case .settings,
             .settingsSubscription,
             .settingsLicense:
            return true
        case .home,
             .diary,
             .recipe,
             .search:
            return false
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    MainView()
}
