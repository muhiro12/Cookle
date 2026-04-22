import SwiftData
import SwiftUI

struct DeleteCategoryButton: View {
    @Environment(Category.self)
    private var category
    @Environment(\.modelContext)
    private var context
    @Environment(TagActionService.self)
    private var tagActionService

    @State private var isPresented = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    private let afterDelete: (() -> Void)?

    var body: some View {
        Button(role: .destructive) {
            isPresented = true
        } label: {
            Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
            }
        }
        .confirmationDialog(
            Text(CategoryDeleteCopy.title(for: category)),
            isPresented: $isPresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await tagActionService.delete(
                            context: context,
                            category: category
                        )
                        afterDelete?()
                    } catch {
                        errorMessage = error.localizedDescription
                        isErrorPresented = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text(CategoryDeleteCopy.message(for: category))
        }
        .alert(
            Text("Cannot Delete Category"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(errorMessage)
        }
    }

    init(afterDelete: (() -> Void)? = nil) {
        self.afterDelete = afterDelete
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    DeleteCategoryButton()
        .environment(categories[0])
}
