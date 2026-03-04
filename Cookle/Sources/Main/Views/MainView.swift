//
//  MainView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/27.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.modelContext)
    private var context
    @Environment(\.requestReview)
    private var requestReview
    @Environment(ConfigurationService.self)
    private var configurationService
    @Environment(MainRouteInbox.self)
    private var routeInbox

    @State private var isUpdateAlertPresented = false
    @State private var navigationState = MainNavigationState()

    var body: some View {
        MainTabView(
            selection: $navigationState.selectedTab,
            diarySelection: $navigationState.selectedDiary,
            diaryRecipeSelection: $navigationState.selectedDiaryRecipe,
            recipeSelection: $navigationState.selectedRecipe,
            searchSelection: $navigationState.selectedSearchRecipe,
            incomingSearchQuery: $navigationState.incomingSearchQuery,
            incomingSettingsSelection: $navigationState.incomingSettingsSelection
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
            applyPendingIntentRouteIfNeededIfPossible()
            applyPendingRouteInboxIfNeededIfPossible()
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else {
                return
            }
            Task {
                try? await configurationService.load()
                isUpdateAlertPresented = configurationService.isUpdateRequired()
            }
            requestReviewIfNeeded()
            applyPendingIntentRouteIfNeededIfPossible()
            applyPendingRouteInboxIfNeededIfPossible()
        }
        .onChange(of: routeInbox.pendingURL) {
            applyPendingRouteInboxIfNeededIfPossible()
        }
        .onOpenURL { deepLinkURL in
            handleIncomingURLIfPossible(deepLinkURL)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard let webpageURL = userActivity.webpageURL else {
                return
            }
            handleIncomingURLIfPossible(webpageURL)
        }
        .sheet(
            isPresented: $navigationState.isCompactSettingsPresented,
            onDismiss: {
                navigationState.compactSettingsSelection = nil
            }
        ) {
            SettingsNavigationView(
                incomingSelection: $navigationState.compactSettingsSelection
            )
        }
    }
}

@MainActor
private extension MainView {
    var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    func applyPendingIntentRouteIfNeededIfPossible() {
        do {
            try MainRouteService.applyPendingIntentRouteIfNeeded(
                state: &navigationState,
                context: context,
                isRegularWidth: isRegularWidth
            )
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func applyPendingRouteInboxIfNeededIfPossible() {
        guard let routeURL = routeInbox.consumePendingURL() else {
            return
        }
        handleIncomingURLIfPossible(routeURL)
    }

    func handleIncomingURLIfPossible(_ url: URL) {
        do {
            try MainRouteService.handleIncomingURL(
                url,
                state: &navigationState,
                context: context,
                isRegularWidth: isRegularWidth
            )
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func requestReviewIfNeeded() {
        guard MainReviewService.shouldRequestReview() else {
            return
        }
        Task {
            try? await Task.sleep(for: MainReviewService.requestDelay)
            requestReview()
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    MainView()
}
