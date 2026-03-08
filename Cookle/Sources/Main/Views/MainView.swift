import MHPlatform
import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.modelContext)
    private var context
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(ConfigurationService.self)
    private var configurationService
    @Environment(NotificationService.self)
    private var notificationService
    @Environment(MHObservableDeepLinkInbox.self)
    private var routeInbox

    @AppStorage(.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(.isICloudOn)
    private var isICloudOn

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
        .mhAppRuntimeLifecycle(
            runtime: appRuntime,
            plan: runtimeLifecyclePlan
        )
        .onChange(of: appRuntime.premiumStatus) {
            syncSubscriptionStateIfNeeded()
        }
        .onChange(of: routeInbox.pendingURL) {
            Task {
                await synchronizePendingRoutesIfPossible()
            }
        }
        .onOpenURL { deepLinkURL in
            Task {
                await routeInbox.ingest(deepLinkURL)
            }
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
            guard let webpageURL = userActivity.webpageURL else {
                return
            }
            Task {
                await routeInbox.ingest(webpageURL)
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

    var runtimeLifecyclePlan: MHAppRuntimeLifecyclePlan {
        .init(
            startupTasks: [
                .init(name: "syncSubscriptionState") {
                    syncSubscriptionStateIfNeeded()
                },
                .init(name: "loadConfiguration") {
                    await refreshConfigurationState()
                },
                .init(name: "synchronizeNotifications") {
                    await notificationService.synchronizeScheduledSuggestions()
                },
                .init(name: "applyPendingRoutes") {
                    await synchronizePendingRoutesIfPossible()
                }
            ],
            activeTasks: [
                .init(name: "syncSubscriptionState") {
                    syncSubscriptionStateIfNeeded()
                },
                .init(name: "loadConfiguration") {
                    await refreshConfigurationState()
                },
                .init(name: "synchronizeNotifications") {
                    await notificationService.synchronizeScheduledSuggestions()
                },
                .init(name: "applyPendingRoutes") {
                    await synchronizePendingRoutesIfPossible()
                }
            ],
            skipFirstActivePhase: true
        )
    }

    var pendingRouteSources: MHDeepLinkSourceChain {
        var sources = [any MHDeepLinkURLSource]()

        if let intentRouteSource = CookleIntentRouteStore.source {
            sources.append(intentRouteSource)
        }

        sources.append(routeInbox)
        return .init(sources)
    }

    func synchronizePendingRoutesIfPossible() async {
        await activateRouteExecutionIfPossible()
        await applyPendingRoutesIfPossible()
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

    func applyPendingRoutesIfPossible() async {
        do {
            navigationState = try await MainRouteService.applyPendingRouteIfNeeded(
                from: pendingRouteSources,
                state: navigationState,
                context: context,
                isRegularWidth: isRegularWidth
            )
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func refreshConfigurationState() async {
        try? await configurationService.load()
        await MainActor.run {
            isUpdateAlertPresented = configurationService.isUpdateRequired()
        }
    }

    func syncSubscriptionStateIfNeeded() {
        switch appRuntime.premiumStatus {
        case .unknown:
            return
        case .inactive:
            isSubscribeOn = false
            isICloudOn = false
        case .active:
            isSubscribeOn = true
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    MainView()
}
