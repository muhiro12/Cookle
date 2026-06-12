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

    @State private var isPresented = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    var body: some View {
        if duplicateCount > 1 {
            Button {
                isPresented = true
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
                isPresented: $isPresented
            ) {
                Button("Merge into \(tag.value)") {
                    mergeDuplicates()
                }
                Button("Cancel", role: .cancel) {
                    // Dismisses the confirmation dialog.
                }
            } message: {
                Text(confirmationMessage)
            }
            .alert(
                Text("Cannot Merge Tags"),
                isPresented: $isErrorPresented
            ) {
                Button("OK", role: .cancel) {
                    // Dismisses the alert.
                }
            } message: {
                Text(errorMessage)
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
        duplicateTags.count
    }

    var duplicateTags: [T] {
        TagOperations.duplicateTags(
            matching: tag,
            in: tags
        )
    }

    var confirmationMessage: String {
        """
        This will reassign recipes from \(duplicateCount - 1) matching tags to \(tag.value), \
        then delete the duplicate tags.
        """
    }

    func mergeDuplicates() {
        Task {
            do {
                try await tagActionService.mergeDuplicates(
                    context: context,
                    keeping: tag
                )
            } catch {
                errorMessage = error.localizedDescription
                isErrorPresented = true
            }
        }
    }
}
