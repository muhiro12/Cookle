//
//  RecipeNoteSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftData
import SwiftUI

struct RecipeNoteSection: View {
    @Environment(Recipe.self)
    private var recipe

    var presentation: RecipeSectionPresentation = .native

    var body: some View {
        if !noteContent.text.isEmpty || noteContent.url != nil {
            RecipeContentSection("Note", presentation: presentation) {
                if !noteContent.text.isEmpty {
                    Text(noteContent.text)
                        .textSelection(.enabled)
                }
                if let url = noteContent.url {
                    Link(destination: url) {
                        Text(url.absoluteString)
                            .multilineTextAlignment(.leading)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: CookleAccessibilityLayout.minimumHitTargetSize,
                                alignment: .leading
                            )
                    }
                }
            }
        }
    }

    private var noteContent: (text: String, url: URL?) {
        let text = recipe.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lastLine = text.split(separator: "\n").last,
              let url = RecipeWebsiteImportOperations.websiteURL(from: String(lastLine)) else {
            return (text, nil)
        }
        return (String(text.dropLast(lastLine.count)).trimmingCharacters(in: .whitespacesAndNewlines), url)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeNoteSection()
            .environment(recipes[0])
    }
}

#Preview("Website reference") {
    let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: Recipe.self,
                configurations: .init(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
        } catch {
            fatalError("Failed to prepare website reference preview: \(error)")
        }
    }()
    let recipe = Recipe.create(context: container.mainContext, content: .init(
        name: "Soup",
        note: "Keep refrigerated.\n\nhttps://recipes.example/vegetable-soup?servings=2"
    ))
    ScrollView {
        RecipeNoteSection(presentation: .reading)
            .environment(recipe)
            .padding()
    }
    .cooklePreviewAppAssembly(CookleAppAssemblyFactory.preview(modelContainer: container))
}
