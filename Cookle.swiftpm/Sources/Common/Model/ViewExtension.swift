import ImagePlayground
import SwiftUI

extension View {
    @ViewBuilder
    func imagePlaygroundSheet(isPresented: Binding<Bool>, recipe: Recipe?, onCompletion: @escaping (URL) -> Void) -> some View {
        if #available(iOS 18.1, *) {
            imagePlaygroundSheet(
                isPresented: isPresented,
                concepts: {
                    var concepts = [ImagePlaygroundConcept]()
                    recipe?.ingredients?.forEach { ingredient in
                        concepts.append(
                            .extracted(
                                from: ingredient.value,
                                title: recipe?.name
                            )
                        )
                    }
                    recipe?.steps.forEach { step in
                        concepts.append(
                            .extracted(
                                from: step,
                                title: recipe?.name
                            )
                        )
                    }
                    return concepts
                }(),
                onCompletion: onCompletion
            )
        }
    }
}
