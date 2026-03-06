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
                guard let appStoreURL = URL(
                    string: "https://apps.apple.com/app/id6483363226"
                ) else {
                    return
                }
                UIApplication.shared.open(appStoreURL)
            } label: {
                Text("Open App Store")
            }
        } message: {
            Text("Please update Cookle to the latest version to continue using it.")
        }
        .task {
            try? await configurationService.load()
            isUpdateAlertPresented = configurationService.isUpdateRequired()
            await synchronizePendingRoutesIfPossible()
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
            Task {
                await synchronizePendingRoutesIfPossible()
            }
        }
        .onChange(of: routeInbox.pendingURL) {
            Task {
                await applyPendingRouteInboxIfNeededIfPossible()
            }
        }
        .onOpenURL { deepLinkURL in
            Task {
                await handleIncomingURLIfPossible(deepLinkURL)
            }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard let webpageURL = userActivity.webpageURL else {
                return
            }
            Task {
                await handleIncomingURLIfPossible(webpageURL)
            }
        }
        .sheet(
            isPresented: $navigationState.isCompactSettingsPresented,
            onDismiss: {
                navigationState.compactSettingsSelection = nil
            },
            content: {
                SettingsNavigationView(
                    incomingSelection: $navigationState.compactSettingsSelection
                )
            }
        )
    }
}

@MainActor
private extension MainView {
    var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    func synchronizePendingRoutesIfPossible() async {
        await activateRouteExecutionIfPossible()
        await applyPendingIntentRouteIfNeededIfPossible()
        await applyPendingRouteInboxIfNeededIfPossible()
    }

    func activateRouteExecutionIfPossible() async {
        do {
            navigationState = try await MainRouteService.activateRouteExecution(
                state: navigationState,
                context: context,
                isRegularWidth: isRegularWidth
            )
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func applyPendingIntentRouteIfNeededIfPossible() async {
        do {
            navigationState = try await MainRouteService.applyPendingIntentRouteIfNeeded(
                state: navigationState,
                context: context,
                isRegularWidth: isRegularWidth
            )
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func applyPendingRouteInboxIfNeededIfPossible() async {
        guard let routeURL = routeInbox.consumePendingURL() else {
            return
        }
        await handleIncomingURLIfPossible(routeURL)
    }

    func handleIncomingURLIfPossible(_ url: URL) async {
        do {
            navigationState = try await MainRouteService.handleIncomingURL(
                url,
                state: navigationState,
                context: context,
                isRegularWidth: isRegularWidth
            )
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func requestReviewIfNeeded() {
        Task {
            _ = await MainReviewService.requestIfNeeded()
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    MainView()
}
