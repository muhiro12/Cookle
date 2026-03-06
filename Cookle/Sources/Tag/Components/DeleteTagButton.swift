import SwiftData
import SwiftUI

struct DeleteTagButton<T: Tag>: View {
    @Environment(T.self)
    private var tag
    @Environment(\.modelContext)
    private var context
    @Environment(TagActionService.self)
    private var tagActionService

    @State private var isConfirmationPresented = false
    @State private var isAlertPresented = false
    @State private var alertMessage = "This item is used by existing recipes."

    private let action: (() -> Void)?

    var body: some View {
        Button(role: .destructive) {
            if let action {
                action()
            } else if tag is Ingredient, tag.recipes.orEmpty.isNotEmpty {
                isAlertPresented = true
            } else {
                isConfirmationPresented = true
            }
        } label: {
            Label {
                Text("Delete")
            } icon: {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
            }
        }
        .alert(
            Text("Cannot Delete"),
            isPresented: $isAlertPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(
            Text("Delete \(tag.value)"),
            isPresented: $isConfirmationPresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await tagActionService.delete(
                            context: context,
                            tag: tag
                        )
                    } catch {
                        alertMessage = error.localizedDescription
                        isAlertPresented = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }

    init(action: (() -> Void)? = nil) {
        self.action = action
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    DeleteTagButton<Category>()
        .environment(categories[0])
}
