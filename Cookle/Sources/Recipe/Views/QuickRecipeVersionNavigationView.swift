import SwiftData
import SwiftUI

@available(iOS 26.0, *)
struct QuickRecipeVersionNavigationView: View {
    let recipe: Recipe
    let quickVersion: QuickRecipeVersion

    var body: some View {
        NavigationStack {
            QuickRecipeVersionView(
                recipe: recipe,
                quickVersion: quickVersion
            )
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    if #available(iOS 26.0, *) {
        QuickRecipeVersionNavigationView(
            recipe: recipes[0],
            quickVersion: .init(
                summary: "A shorter view for quick reference.",
                estimatedCookingTime: 10,
                steps: [
                    "Prep ingredients.",
                    "Cook and finish."
                ]
            )
        )
    }
}
