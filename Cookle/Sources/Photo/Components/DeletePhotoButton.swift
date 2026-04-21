import SwiftData
import SwiftUI

struct DeletePhotoButton: View {
    @Environment(Photo.self)
    private var photo
    @Environment(\.modelContext)
    private var context
    @Environment(PhotoActionService.self)
    private var photoActionService

    @State private var isPresented = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    private let afterDelete: (() -> Void)?

    var body: some View {
        Button(role: .destructive) {
            isPresented = true
        } label: {
            Label {
                Text("Delete Photo")
            } icon: {
                Image(systemName: "trash")
                    .accessibilityHidden(true)
            }
        }
        .confirmationDialog(
            Text(PhotoDeleteCopy.title(for: photo)),
            isPresented: $isPresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        _ = try await photoActionService.delete(
                            context: context,
                            photo: photo
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
            Text(PhotoDeleteCopy.message(for: photo))
        }
        .alert(
            Text("Cannot Delete Photo"),
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
    @Previewable @Query var photos: [Photo]
    DeletePhotoButton()
        .environment(photos[0])
}
