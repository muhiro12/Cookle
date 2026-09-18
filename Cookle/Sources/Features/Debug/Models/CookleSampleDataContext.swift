import Foundation
import SwiftData

enum CookleSampleDataContext {
    static func makeSharedContext() -> CookleAppAssembly {
        makePreparedContext(
            photoDirectoryURL: nil,
            baseDate: nil,
            makeAssembly: CookleAppAssemblyFactory.preview
        ).assembly
    }

    #if DEBUG
    /// Builds an isolated in-memory assembly for App Store screenshot capture runs.
    static func makeCaptureContext() -> CookleAppAssembly {
        let preparedContext = makePreparedContext(
            photoDirectoryURL: CookleCaptureConfiguration.photoDirectoryURL,
            baseDate: CookleCaptureConfiguration.baseDate,
            makeAssembly: CookleAppAssemblyFactory.capture
        )
        MainActor.assumeIsolated {
            CookleCaptureConfiguration.screen.apply(
                to: preparedContext.assembly.navigationModel,
                recipes: preparedContext.recipes,
                diaries: preparedContext.diaries
            )
        }
        return preparedContext.assembly
    }
    #endif
}

private extension CookleSampleDataContext {
    struct PreparedContext {
        let assembly: CookleAppAssembly
        let recipes: [Recipe]
        let diaries: [Diary]
    }

    static func makePreparedContext(
        photoDirectoryURL: URL?,
        baseDate: Date?,
        makeAssembly: @MainActor (ModelContainer) -> CookleAppAssembly
    ) -> PreparedContext {
        do {
            let modelContainer = try ModelContainer(
                for: Recipe.self,
                configurations: .init(
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
            )
            let previewStore = CooklePreviewStore()
            previewStore.localPhotoDirectoryURL = photoDirectoryURL
            if let baseDate {
                previewStore.baseDate = baseDate
            }
            try previewStore.prepare(modelContainer.mainContext)
            return MainActor.assumeIsolated {
                .init(
                    assembly: makeAssembly(modelContainer),
                    recipes: previewStore.preparedRecipes,
                    diaries: previewStore.preparedDiaries
                )
            }
        } catch {
            fatalError("Failed to create shared Cookle sample data context: \(error.localizedDescription)")
        }
    }
}
