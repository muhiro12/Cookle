import SwiftData
import SwiftUI

/// Confirms a recipe deletion against the reviewed impact.
///
/// Every in-app route that deletes a recipe presents this review, so the
/// confirmation always quotes the affected diary meal rows and deletes only
/// what was reviewed. When those rows change before confirmation, the review
/// reopens with the current rows instead of deleting.
struct RecipeDeletionReviewModifier: ViewModifier {
    @Environment(\.modelContext)
    private var context
    @Environment(RecipeActionService.self)
    private var recipeActionService

    @Binding var review: RecipeDeletionReview?

    @State private var changedReview: RecipeDeletionReview?
    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .alert(
                Text(review.map(RecipeDeleteCopy.title) ?? ""),
                isPresented: isReviewPresented,
                presenting: review
            ) { presentedReview in
                Button("Delete", role: .destructive) {
                    delete(presentedReview)
                }
                Button("Cancel", role: .cancel) {
                    changedReview = nil
                }
            } message: { presentedReview in
                Text(message(for: presentedReview))
            }
            .alert(
                Text("Cannot Delete Recipe"),
                isPresented: isErrorPresented
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
    }
}

private extension RecipeDeletionReviewModifier {
    var isReviewPresented: Binding<Bool> {
        .init(
            get: {
                review != nil
            },
            set: { isPresented in
                if isPresented == false {
                    review = nil
                }
            }
        )
    }

    var isErrorPresented: Binding<Bool> {
        .init(
            get: {
                errorMessage != nil
            },
            set: { isPresented in
                if isPresented == false {
                    errorMessage = nil
                }
            }
        )
    }

    func message(for presentedReview: RecipeDeletionReview) -> String {
        let message = RecipeDeleteCopy.message(for: presentedReview)
        guard presentedReview == changedReview else {
            return message
        }

        return ReviewExampleCopy.changedNotice + "\n\n" + message
    }

    func delete(_ reviewedDeletion: RecipeDeletionReview) {
        Task {
            do {
                switch try await recipeActionService.delete(
                    context: context,
                    reviewed: reviewedDeletion
                ) {
                case .applied:
                    changedReview = nil
                case .changed(let currentReview):
                    changedReview = currentReview
                    review = currentReview
                case .targetMissing:
                    changedReview = nil
                    errorMessage = ReviewExampleCopy.missingMessage(
                        for: reviewedDeletion.recipeName
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
