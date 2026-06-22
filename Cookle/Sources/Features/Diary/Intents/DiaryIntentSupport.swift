import SwiftData

enum DiaryIntentSupport {
    @MainActor
    static func resolveRecipes(
        from entities: Set<RecipeEntity>,
        context: ModelContext
    ) -> [Recipe] {
        entities.compactMap { entity in
            try? entity.model(context: context)
        }
        .sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
