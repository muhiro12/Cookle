import PhotosUI
import SwiftUI

struct RecipePhotoTextImportView: View {
    @Environment(\.dismiss)
    private var dismiss
    @State private var selection: PhotosPickerItem?
    @State private var isCameraPresented = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    let onImport: (Data) -> Void

    var body: some View {
        NavigationStack {
            importForm
        }
    }

    private var importForm: some View {
        Form {
            Section {
                PhotosPicker(selection: $selection, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                }
                if RecipePhotoInputSource.camera.isAvailable {
                    Button("Take Photo", systemImage: "camera") {
                        isCameraPresented = true
                    }
                }
            } footer: {
                Text("""
                    Review the text, then use Apple Intelligence to create an editable recipe draft. \
                    Photos here are read for text, not attached to the recipe.
                    """)
            }
        }
        .disabled(isLoading)
        .navigationTitle("Read Recipe from Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { data in
                onImport(data)
            }
        }
        .task(id: selection) {
            await loadPhoto()
        }
        .alert("Cannot Infer Recipe", isPresented: .init(
            get: { !errorMessage.isEmpty },
            set: { isPresented in
                if !isPresented {
                    errorMessage = ""
                }
            }
        )) {
            Button("OK", role: .cancel) {
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadPhoto() async {
        guard let selection else {
            return
        }
        isLoading = true
        defer {
            isLoading = false
        }
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                throw RecipeTextImportError.photoDataUnavailable
            }
            try Task.checkCancellation()
            onImport(data)
        } catch {
            guard !Task.isCancelled else {
                return
            }
            errorMessage = RecipeTextImportError.photoDataUnavailable.localizedDescription
            self.selection = nil
        }
    }
}
