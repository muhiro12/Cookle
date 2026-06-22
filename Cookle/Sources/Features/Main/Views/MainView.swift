import MHPlatform
import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(RemoteConfigurationService.self)
    private var remoteConfigurationService
    @Environment(MainNavigationModel.self)
    private var navigationModel
    @Environment(MHAppRoutePipeline<CookleRoute>.self)
    private var routePipeline
    @Environment(\.modelContext)
    private var modelContext
    @Environment(CookleAppLogging.self)
    private var logging

    var body: some View {
        @Bindable var navigationModel = navigationModel

        MainTabView(
            selection: $navigationModel.selectedTab,
            diarySelection: $navigationModel.selectedDiary,
            diaryRecipeSelection: $navigationModel.selectedDiaryRecipe,
            recipeSelection: $navigationModel.selectedRecipe,
            photoSelection: $navigationModel.selectedPhoto,
            searchSelection: $navigationModel.selectedSearchRecipe,
            tagBrowser: $navigationModel.selectedTagBrowser,
            categorySelection: $navigationModel.selectedCategory,
            categoryRecipeSelection: $navigationModel.selectedCategoryRecipe,
            ingredientSelection: $navigationModel.selectedIngredient,
            ingredientRecipeSelection: $navigationModel.selectedIngredientRecipe,
            incomingSearchQuery: $navigationModel.incomingSearchQuery,
            incomingSettingsSelection: $navigationModel.incomingSettingsSelection
        )
        .openCookleRoute { route in
            openRoute(route)
        }
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
            handleRouteParseFailureIfNeeded()
        }
        .onChange(of: routePipeline.lastParseFailureURL) {
            handleRouteParseFailureIfNeeded()
        }
    }
}

@MainActor
private extension MainView {
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

        let routeLogger = logging.logger(
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

    func openRoute(_ route: CookleRoute) {
        do {
            try MainNavigationRouter(
                navigationModel: navigationModel
            )
            .apply(
                route: route,
                context: modelContext
            )
        } catch {
            let routeLogger = logging.logger(
                category: "RouteExecution",
                source: #fileID
            )
            routeLogger.error(
                "in-app route execution failed",
                metadata: [
                    "error": error.localizedDescription
                ]
            )
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    MainView()
}
