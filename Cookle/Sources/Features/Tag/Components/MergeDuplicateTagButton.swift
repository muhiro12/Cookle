import SwiftData
import SwiftUI

struct MergeDuplicateTagButton<T: Tag>: View {
    @Environment(T.self)
    private var tag
    @Environment(\.modelContext)
    private var context
    @Environment(TagActionService.self)
    private var tagActionService

    @Query(T.descriptor(.all))
    private var tags: [T]

    @State private var review: TagMergeReview<T>?
    @State private var changedReview: TagMergeReview<T>?
    @State private var errorMessage: String?

    var body: some View {
        if duplicateCount > 1 {
            Button {
                reviewMerge()
            } label: {
                Label {
                    Text("Merge duplicate \(tag.value)")
                } icon: {
                    Image(systemName: "arrow.triangle.merge")
                        .accessibilityHidden(true)
                }
            }
            .confirmationDialog(
                Text("Merge Duplicate Tags"),
                isPresented: isReviewPresented,
                presenting: review
            ) { presentedReview in
                Button("Merge into \(presentedReview.keptValue)") {
                    merge(presentedReview)
                }
                Button("Cancel", role: .cancel) {
                    changedReview = nil
                }
            } message: { presentedReview in
                Text(message(for: presentedReview))
            }
            .alert(
                Text("Cannot Merge Tags"),
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
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var ingredients: [Ingredient]
    MergeDuplicateTagButton<Ingredient>()
        .environment(ingredients[0])
}

private extension MergeDuplicateTagButton {
    var duplicateCount: Int {
        TagOperations.duplicateTags(
            matching: tag,
            in: tags
        ).count
    }

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

    func message(for presentedReview: TagMergeReview<T>) -> String {
        let matchingTags = ReviewExampleCopy.list(
            presentedReview.duplicateValueExamples,
            totalCount: presentedReview.duplicateCount
        )
        var sections = [
            impactMessage(for: presentedReview),
            String(localized: "Matching tags: \(matchingTags).")
        ]
        if presentedReview.recipeCount > .zero {
            let recipes = ReviewExampleCopy.list(
                presentedReview.recipeNameExamples,
                totalCount: presentedReview.recipeCount
            )
            sections.append(
                String(localized: "Recipes: \(recipes).")
            )
        }
        if presentedReview == changedReview {
            sections.insert(
                ReviewExampleCopy.changedNotice,
                at: .zero
            )
        }
        return sections.joined(separator: "\n\n")
    }

    func impactMessage(for presentedReview: TagMergeReview<T>) -> String {
        if presentedReview.duplicateCount == 1 {
            return String(
                localized: """
                This will reassign recipes from one matching tag to \(presentedReview.keptValue), \
                then delete the duplicate tag.
                """
            )
        }

        return String(
            localized: """
            This will reassign recipes from \(presentedReview.duplicateCount) matching tags to \
            \(presentedReview.keptValue), then delete the duplicate tags.
            """
        )
    }

    func reviewMerge() {
        do {
            changedReview = nil
            review = try TagOperations.mergeReview(
                context: context,
                keeping: tag
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func merge(_ reviewedMerge: TagMergeReview<T>) {
        Task {
            do {
                switch try await tagActionService.mergeDuplicates(
                    context: context,
                    reviewed: reviewedMerge
                ) {
                case .applied:
                    changedReview = nil
                case .changed(let currentReview) where currentReview.hasDuplicates:
                    changedReview = currentReview
                    review = currentReview
                case .changed:
                    changedReview = nil
                    errorMessage = String(
                        localized: "No matching tags remain to merge. Nothing was changed."
                    )
                case .targetMissing:
                    changedReview = nil
                    errorMessage = ReviewExampleCopy.missingMessage(
                        for: reviewedMerge.keptValue
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
