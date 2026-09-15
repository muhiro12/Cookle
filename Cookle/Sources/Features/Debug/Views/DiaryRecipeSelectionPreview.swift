import SwiftData
import SwiftUI

#if DEBUG
struct DiaryRecipeSelectionPreview: View {
    static let assembly: CookleAppAssembly = {
        do {
            let container = try ModelContainer(
                for: Recipe.self,
                configurations: .init(
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
            )
            try CooklePreviewStore().prepare(container.mainContext)
            return CookleAppAssemblyFactory.preview(modelContainer: container)
        } catch {
            fatalError("Failed to prepare recipe selection preview: \(error)")
        }
    }()

    @Query(.recipes(.all))
    private var recipes: [Recipe]

    let selectedCount: Int

    var body: some View {
        NavigationStack {
            DiaryFormRecipeListView(
                selection: .constant(Set(recipes.prefix(selectedCount))),
                type: .dinner
            )
        }
    }
}

#endif
