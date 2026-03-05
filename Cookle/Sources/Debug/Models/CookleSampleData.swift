import GoogleMobileAdsWrapper
import StoreKitWrapper
import SwiftData
import SwiftUI

struct CookleSampleData: PreviewModifier {
    struct Context {
        let modelContainer: ModelContainer
        let store: Store
        let googleMobileAdsController: GoogleMobileAdsController
        let routeInbox: MainRouteInbox
        let notificationService: NotificationService
        let tipController: CookleTipController
        let configurationService: ConfigurationService
        let recipeActionService: RecipeActionService
        let diaryActionService: DiaryActionService
        let tagActionService: TagActionService
        let settingsActionService: SettingsActionService
    }

    static func makeSharedContext() -> Context {
        CookleSampleDataContext.sharedContext
    }

    func body(content: Content, context: Context) -> some View {
        content
            .modelContainer(context.modelContainer)
            .environment(context.store)
            .environment(context.googleMobileAdsController)
            .environment(context.routeInbox)
            .environment(context.notificationService)
            .environment(context.tipController)
            .environment(context.configurationService)
            .environment(context.recipeActionService)
            .environment(context.diaryActionService)
            .environment(context.tagActionService)
            .environment(context.settingsActionService)
    }
}
