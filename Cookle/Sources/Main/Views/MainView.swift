import MHPlatform
import SwiftUI

struct MainView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(ConfigurationService.self)
    private var configurationService
    @Environment(MainNavigationModel.self)
    private var navigationModel

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
        }
        .onChange(of: horizontalSizeClass) {
            navigationModel.isRegularWidth = isRegularWidth
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
                configurationService.isUpdateRequired()
            },
            set: { _ in
                // Update-required presentation is controlled by remote configuration.
            }
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    MainView()
}
