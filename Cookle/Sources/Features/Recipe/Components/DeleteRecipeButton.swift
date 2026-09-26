import SwiftData
import SwiftUI

struct DeleteRecipeButton: View {
    @Environment(Recipe.self)
    private var recipe

    @State private var deletionReview: RecipeDeletionReview?

    private let requestReview: ((RecipeDeletionReview) -> Void)?
    private let showsRecipeName: Bool

    var body: some View {
        Button(role: .destructive) {
            let review = RecipeOperations.deletionReview(
                for: recipe
            )
            if let requestReview {
                requestReview(review)
            } else {
                deletionReview = review
            }
        } label: {
            Label {
                if showsRecipeName {
                    Text("Delete \(recipe.name)")
                } else {
                    Text("Delete")
                }
            } icon: {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
            }
        }
        .recipeDeletionReview($deletionReview)
    }

    /// Creates a delete button.
    ///
    /// - Parameter requestReview: Receives the built review when an ancestor
    ///   presents it, such as a context menu whose content closes before the
    ///   confirmation appears. The deletion still requires that review.
    init(
        showsRecipeName: Bool = true,
        requestReview: ((RecipeDeletionReview) -> Void)? = nil
    ) {
        self.showsRecipeName = showsRecipeName
        self.requestReview = requestReview
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    DeleteRecipeButton()
        .environment(recipes[0])
}
