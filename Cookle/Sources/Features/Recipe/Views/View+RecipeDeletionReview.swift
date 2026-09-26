import SwiftUI

extension View {
    /// Presents `review` for confirmation and deletes only the reviewed recipe impact.
    func recipeDeletionReview(
        _ review: Binding<RecipeDeletionReview?>
    ) -> some View {
        modifier(
            RecipeDeletionReviewModifier(
                review: review
            )
        )
    }
}
