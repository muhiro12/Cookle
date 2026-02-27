import GoogleMobileAdsWrapper
import StoreKitWrapper
import SwiftData
import SwiftUI

private enum CookleSampleDataContext {
    static let previewStore = CooklePreviewStore()

    static let sharedContext: CookleSampleData.Context = {
        do {
            let modelContainer = try ModelContainer(
                for: Recipe.self,
                configurations: .init(isStoredInMemoryOnly: true)
            )
            previewStore.prepare(modelContainer.mainContext)

            return .init(
                modelContainer: modelContainer,
                store: .init(),
                googleMobileAdsController: .init(adUnitID: Secret.adUnitIDDev),
                notificationService: .init(modelContainer: modelContainer)
            )
        } catch {
            fatalError("Failed to create shared Cookle sample data context: \(error.localizedDescription)")
        }
    }()
}

struct CookleSampleData: PreviewModifier {
    struct Context {
        let modelContainer: ModelContainer
        let store: Store
        let googleMobileAdsController: GoogleMobileAdsController
        let notificationService: NotificationService
    }

    static func makeSharedContext() -> Context {
        CookleSampleDataContext.sharedContext
    }

    func body(content: Content, context: Context) -> some View {
        content
            .modelContainer(context.modelContainer)
            .environment(context.store)
            .environment(context.googleMobileAdsController)
            .environment(context.notificationService)
    }
}
