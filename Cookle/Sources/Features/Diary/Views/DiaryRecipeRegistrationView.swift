import MHUI
import SwiftData
import SwiftUI

struct DiaryRecipeRegistrationView: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var context
    @Environment(RecipeActionService.self)
    private var recipeActionService

    @State private var name = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let onRegistration: (Recipe) -> Void

    var body: some View {
        NavigationStack {
            Form {
                RecipeFormNameSection($name, showsQuickCaptureHint: true)
                Section {
                    Text("The recipe stays in your collection even if you cancel the Diary.")
                        .foregroundStyle(.secondary)
                }
            }
            .mhFormChrome()
            .disabled(isSaving)
            .navigationTitle("New Recipe")
            .interactiveDismissDisabled(!name.isEmpty || isSaving)
            .toolbar {
                toolbarItems
            }
            .alert("Cannot Save Recipe", isPresented: isErrorPresented) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

private extension DiaryRecipeRegistrationView {
    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .disabled(isSaving)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Register Recipe") {
                Task {
                    await registerRecipe()
                }
            }
            .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    var isErrorPresented: Binding<Bool> {
        .init(get: { errorMessage != nil }, set: { isPresented in
            if !isPresented {
                errorMessage = nil
            }
        })
    }

    func registerRecipe() async {
        guard !isSaving else {
            return
        }
        isSaving = true
        defer {
            isSaving = false
        }
        do {
            let draft = try RecipeFormOperations.makeDraft(
                input: .init(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    servingSize: .zero,
                    cookingTime: .zero,
                    ingredientsText: "",
                    stepsText: "",
                    categoriesText: "",
                    note: ""
                )
            )
            let outcome = try await recipeActionService.create(
                context: context,
                draft: draft,
                requestReview: false
            )
            onRegistration(outcome.value)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
#Preview {
    DiaryRecipeRegistrationView { _ in
        // Preview registration does not persist a Diary.
    }
    .cooklePreviewAppAssembly(DiaryRecipeSelectionPreview.assembly)
}
#endif
