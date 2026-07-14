import AppIntents
import Foundation
import ImagePlayground
import SwiftUI

@available(iOS 18.1, *)
struct CookleImagePlaygroundModifier: ViewModifier {
    nonisolated private struct LoadRequest: Sendable {
        let id = UUID()
        let url: URL
    }

    nonisolated private enum DataLoader {
        static func data(
            from url: URL
        ) async -> Data? {
            let loadingTask = Task.detached(priority: .userInitiated) {
                guard Task.isCancelled == false else {
                    return Data?.none
                }

                let data = try? Data(contentsOf: url)
                guard Task.isCancelled == false else {
                    return nil
                }
                return data
            }
            return await withTaskCancellationHandler {
                await loadingTask.value
            } onCancel: {
                loadingTask.cancel()
            }
        }
    }

    @Binding private var isPresented: Bool
    @State private var loadRequest: LoadRequest?
    @State private var hasResolvedPresentation = false

    private let recipe: Recipe?
    private let onCompletion: (Data) -> Void
    private let onCancellation: (() -> Void)?

    init(
        isPresented: Binding<Bool>,
        recipe: Recipe?,
        onCompletion: @escaping (Data) -> Void,
        onCancellation: (() -> Void)?
    ) {
        _isPresented = isPresented
        self.recipe = recipe
        self.onCompletion = onCompletion
        self.onCancellation = onCancellation
    }

    func body(content: Content) -> some View {
        content
            .imagePlaygroundSheet(
                isPresented: $isPresented,
                concepts: imagePlaygroundConcepts(for: recipe)
            ) { url in
                queueLoad(from: url)
            } onCancellation: {
                finishWithCancellation()
            }
            .onChange(of: isPresented) {
                handlePresentationChange()
            }
            .task(id: loadRequest?.id) {
                await loadGeneratedImage()
            }
    }

    private func handlePresentationChange() {
        guard isPresented else {
            return
        }

        loadRequest = nil
        hasResolvedPresentation = false
    }

    private func queueLoad(
        from url: URL
    ) {
        guard hasResolvedPresentation == false else {
            return
        }

        hasResolvedPresentation = true
        loadRequest = .init(url: url)
    }

    private func finishWithCancellation() {
        guard hasResolvedPresentation == false else {
            return
        }

        hasResolvedPresentation = true
        loadRequest = nil
        onCancellation?()
    }

    private func loadGeneratedImage() async {
        guard let request = loadRequest else {
            return
        }

        let data = await DataLoader.data(
            from: request.url
        )
        guard Task.isCancelled == false,
              loadRequest?.id == request.id else {
            return
        }

        guard let data else {
            loadRequest = nil
            return
        }

        onCompletion(data)
        loadRequest = nil
    }

    private func imagePlaygroundConcepts(for recipe: Recipe?) -> [ImagePlaygroundConcept] {
        guard let recipe else {
            return []
        }

        let ingredients = recipe.ingredientObjects?.sorted().compactMap { object in
            object.ingredient?.value
        } ?? []
        guard let draft = RecipeOperations.makeImageConceptDraft(
            request: .init(
                name: recipe.name,
                ingredients: ingredients,
                steps: recipe.steps
            )
        ) else {
            return []
        }

        var concepts = [ImagePlaygroundConcept]()
        concepts.append(
            .text(draft.title)
        )
        draft.ingredients.forEach { ingredient in
            concepts.append(
                .text(ingredient)
            )
        }
        if let combinedSteps = draft.combinedSteps {
            concepts.append(
                .extracted(from: combinedSteps, title: draft.title)
            )
        }
        return concepts
    }
}
