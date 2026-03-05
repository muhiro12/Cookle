import GoogleMobileAdsWrapper
import StoreKitWrapper
import SwiftData

enum CookleSampleDataContext {
    struct Services {
        let routeInbox: MainRouteInbox
        let notificationService: NotificationService
        let tipController: CookleTipController
        let configurationService: ConfigurationService
        let recipeActionService: RecipeActionService
        let diaryActionService: DiaryActionService
        let tagActionService: TagActionService
        let settingsActionService: SettingsActionService
    }

    static let previewStore = CooklePreviewStore()

    static let sharedContext: CookleSampleData.Context = makeSharedContext()

    static func makeSharedContext() -> CookleSampleData.Context {
        do {
            let modelContainer = try ModelContainer(
                for: Recipe.self,
                configurations: .init(isStoredInMemoryOnly: true)
            )
            previewStore.prepare(modelContainer.mainContext)
            let services = makeServices(modelContainer: modelContainer)

            return .init(
                modelContainer: modelContainer,
                store: .init(),
                googleMobileAdsController: .init(adUnitID: Secret.adUnitIDDev),
                routeInbox: services.routeInbox,
                notificationService: services.notificationService,
                tipController: services.tipController,
                configurationService: services.configurationService,
                recipeActionService: services.recipeActionService,
                diaryActionService: services.diaryActionService,
                tagActionService: services.tagActionService,
                settingsActionService: services.settingsActionService
            )
        } catch {
            fatalError("Failed to create shared Cookle sample data context: \(error.localizedDescription)")
        }
    }

    static func makeServices(modelContainer: ModelContainer) -> Services {
        MainActor.assumeIsolated {
            let tipController = CookleTipController()
            try? tipController.configureIfNeeded()
            let routeInbox = MainRouteInbox()
            let notificationService = NotificationService(
                modelContainer: modelContainer,
                routeInbox: routeInbox
            )
            return .init(
                routeInbox: routeInbox,
                notificationService: notificationService,
                tipController: tipController,
                configurationService: .init(),
                recipeActionService: .init(notificationService: notificationService),
                diaryActionService: .init(),
                tagActionService: .init(),
                settingsActionService: .init(notificationService: notificationService)
            )
        }
    }
}
