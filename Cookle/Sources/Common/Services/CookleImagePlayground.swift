//
//  CookleImagePlayground.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/30.
//

import AppIntents
import ImagePlayground
import SwiftUI

enum CookleImagePlayground {
    static var isSupported: Bool {
        if #available(iOS 18.1, *) {
            EnvironmentValues().supportsImagePlayground
        } else {
            false
        }
    }
}

extension View {
    @ViewBuilder
    func cookleImagePlayground(
        isPresented: Binding<Bool>,
        recipe: Recipe?,
        onCompletion: @escaping (Data) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        if #available(iOS 18.1, *) {
            imagePlaygroundSheet(
                isPresented: isPresented,
                concepts: imagePlaygroundConcepts(for: recipe)
            ) { url in
                guard let data = try? Data(contentsOf: url) else {
                    return
                }
                onCompletion(data)
            } onCancellation: {
                onCancellation?()
            }
        }
    }

    @available(iOS 18.1, *)
    private func imagePlaygroundConcepts(for recipe: Recipe?) -> [ImagePlaygroundConcept] {
        guard let recipe else {
            return .empty
        }

        let ingredients = recipe.ingredientObjects?.sorted().compactMap { object in
            object.ingredient?.value
        } ?? .empty
        guard let draft = RecipeImageConceptService.makeDraft(
            request: .init(
                name: recipe.name,
                ingredients: ingredients,
                steps: recipe.steps
            )
        ) else {
            return .empty
        }

        var concepts = [ImagePlaygroundConcept].empty
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
