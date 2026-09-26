import SwiftData
import SwiftUI

struct DeleteCategoryButton: View {
    @Environment(Category.self)
    private var category
    @Environment(\.modelContext)
    private var context
    @Environment(TagActionService.self)
    private var tagActionService

    @State private var review: TagDeletionReview<Category>?
    @State private var changedReview: TagDeletionReview<Category>?
    @State private var errorMessage: String?
    @State private var leavesAfterError = false

    private let afterDelete: (() -> Void)?

    var body: some View {
        Button(role: .destructive) {
            changedReview = nil
            review = TagOperations.deletionReview(
                for: category
            )
        } label: {
            Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
            }
        }
        .confirmationDialog(
            Text(review.map(CategoryDeleteCopy.title) ?? ""),
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
            Text("Cannot Delete Category"),
            isPresented: isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
                leaveIfTagIsGone()
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    init(afterDelete: (() -> Void)? = nil) {
        self.afterDelete = afterDelete
    }
}

private extension DeleteCategoryButton {
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
                    leaveIfTagIsGone()
                }
            }
        )
    }

    func leaveIfTagIsGone() {
        guard leavesAfterError else {
            return
        }

        leavesAfterError = false
        afterDelete?()
    }

    func message(for presentedReview: TagDeletionReview<Category>) -> String {
        let message = CategoryDeleteCopy.message(for: presentedReview)
        guard presentedReview == changedReview else {
            return message
        }

        return ReviewExampleCopy.changedNotice + "\n\n" + message
    }

    func delete(_ reviewedDeletion: TagDeletionReview<Category>) {
        Task {
            do {
                switch try await tagActionService.delete(
                    context: context,
                    reviewed: reviewedDeletion
                ) {
                case .applied:
                    changedReview = nil
                    afterDelete?()
                case .changed(let currentReview):
                    changedReview = currentReview
                    review = currentReview
                case .targetMissing:
                    changedReview = nil
                    // The tag is already gone; leave its screen once the user has read why.
                    leavesAfterError = true
                    errorMessage = ReviewExampleCopy.missingMessage(
                        for: reviewedDeletion.value
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    DeleteCategoryButton()
        .environment(categories[0])
}
