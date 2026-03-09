import SwiftData

enum CookleSampleDataContext {
    static func makeSharedContext() -> CooklePlatformEnvironment {
        do {
            let modelContainer = try ModelContainer(
                for: Recipe.self,
                configurations: .init(isStoredInMemoryOnly: true)
            )
            let previewStore = CooklePreviewStore()
            previewStore.prepare(modelContainer.mainContext)
            return MainActor.assumeIsolated {
                CooklePlatformEnvironmentFactory.preview(
                    modelContainer: modelContainer
                )
            }
        } catch {
            fatalError("Failed to create shared Cookle sample data context: \(error.localizedDescription)")
        }
    }
}
