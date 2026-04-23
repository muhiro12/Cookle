import SwiftData
import SwiftUI

@available(iOS 26.0, *)
struct QuickRecipeVersionButton: View {
    @Environment(Recipe.self)
    private var recipe

    @State private var quickVersion: QuickRecipeVersion?
    @State private var isPresented = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        if recipe.steps.isNotEmpty {
            Button {
                generateOrPresentQuickVersion()
            } label: {
                Label {
                    HStack {
                        Text("Quick Version")
                        Spacer()
                        if isLoading {
                            ProgressView()
                        }
                    }
                } icon: {
                    Image(systemName: "bolt")
                        .accessibilityHidden(true)
                }
            }
            .disabled(isLoading)
            .sheet(isPresented: $isPresented) {
                if let quickVersion {
                    QuickRecipeVersionNavigationView(
                        recipe: recipe,
                        quickVersion: quickVersion
                    )
                }
            }
            .alert(
                Text("Cannot Create Quick Version"),
                isPresented: isErrorPresented
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = .empty
                }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: recipe.persistentModelID) {
                resetQuickVersion()
            }
        }
    }
}

@available(iOS 26.0, *)
private extension QuickRecipeVersionButton {
    var isErrorPresented: Binding<Bool> {
        .init(
            get: {
                errorMessage.isNotEmpty
            },
            set: { isPresented in
                if isPresented == false {
                    errorMessage = .empty
                }
            }
        )
    }

    var quickVersionRequest: QuickRecipeVersionRequest {
        .init(
            name: recipe.name,
            cookingTime: recipe.cookingTime,
            ingredients: recipe.ingredientObjects?.sorted().compactMap { ingredientObject in
                ingredientObject.ingredient?.value
            } ?? [],
            steps: recipe.steps
        )
    }

    func generateOrPresentQuickVersion() {
        if quickVersion != nil {
            isPresented = true
            return
        }

        isLoading = true
        Task {
            await generateQuickVersion()
        }
    }

    @MainActor
    func generateQuickVersion() async {
        defer {
            isLoading = false
        }

        do {
            quickVersion = try await QuickRecipeVersionService.makeVersion(
                request: quickVersionRequest
            )
            isPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetQuickVersion() {
        quickVersion = nil
        isPresented = false
        isLoading = false
        errorMessage = .empty
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    if #available(iOS 26.0, *) {
        List {
            QuickRecipeVersionButton()
                .environment(recipes[0])
        }
    }
}
