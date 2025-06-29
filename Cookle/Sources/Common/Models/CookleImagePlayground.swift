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
        recipe: RecipeEntity?,
        onCompletion: @escaping (Data) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        if #available(iOS 18.1, *) {
            imagePlaygroundSheet(
                isPresented: isPresented,
                concepts: {
                    var concepts = [ImagePlaygroundConcept].empty
                    guard let recipe else {
                        return concepts
                    }
                    concepts.append(
                        .text(recipe.name)
                    )
                    recipe.ingredients.forEach { element in
                        concepts.append(
                            .text(element.ingredient)
                        )
                    }
                    recipe.steps.forEach { step in
                        concepts.append(
                            .extracted(from: step, title: recipe.name)
                        )
                    }
                    return concepts
                }()
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
}
