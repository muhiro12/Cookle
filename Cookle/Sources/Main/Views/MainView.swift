import MHPlatform
import SwiftUI

struct MainView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(RemoteConfigurationService.self)
    private var remoteConfigurationService
    @Environment(MainNavigationModel.self)
    private var navigationModel
    @Environment(MHAppRoutePipeline<CookleRoute>.self)
    private var routePipeline

    var body: some View {
        @Bindable var navigationModel = navigationModel

        MainTabView(
            selection: $navigationModel.selectedTab,
            diarySelection: $navigationModel.selectedDiary,
            diaryRecipeSelection: $navigationModel.selectedDiaryRecipe,
            recipeSelection: $navigationModel.selectedRecipe,
            searchSelection: $navigationModel.selectedSearchRecipe,
            incomingSearchQuery: $navigationModel.incomingSearchQuery,
            incomingSettingsSelection: $navigationModel.incomingSettingsSelection
        )
        .alert(Text("Update Required"), isPresented: isUpdateRequiredBinding) {
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
        .onAppear {
            navigationModel.isRegularWidth = isRegularWidth
            handleRouteParseFailureIfNeeded()
        }
        .onChange(of: horizontalSizeClass) {
            navigationModel.isRegularWidth = isRegularWidth
        }
        .onChange(of: routePipeline.lastParseFailureURL) {
            handleRouteParseFailureIfNeeded()
        }
        .sheet(
            isPresented: $navigationModel.isCompactSettingsPresented,
            onDismiss: {
                navigationModel.compactSettingsSelection = nil
            },
            content: {
                SettingsNavigationView(
                    incomingSelection: $navigationModel.compactSettingsSelection
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

    var isUpdateRequiredBinding: Binding<Bool> {
        .init(
            get: {
                remoteConfigurationService.isUpdateRequired()
            },
            set: { _ in
                // Update-required presentation is controlled by remote configuration.
            }
        )
    }

    func handleRouteParseFailureIfNeeded() {
        guard let invalidURL = routePipeline.lastParseFailureURL else {
            return
        }

        let routeLogger = CookleApp.logger(
            category: "RouteParseFailure",
            source: #fileID
        )
        routeLogger.warning(
            "deep-link route parse failed",
            metadata: [
                "url": invalidURL.absoluteString
            ]
        )
        routePipeline.clearLastParseFailure()
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    MainView()
}
