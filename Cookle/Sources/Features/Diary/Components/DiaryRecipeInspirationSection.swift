import SwiftUI

struct DiaryRecipeInspirationSection: View {
    private static let candidateCount = 3

    @State private var offset = 0

    let recipes: [Recipe]
    let openRecipe: (Recipe) -> Void

    var body: some View {
        Section {
            if recipes.isEmpty {
                AddRecipeButton(showsTitle: true)
            } else {
                ForEach(candidates) { recipe in
                    Button {
                        openRecipe(recipe)
                    } label: {
                        RecipeLabel()
                            .labelStyle(.titleAndLargeIcon)
                            .environment(recipe)
                            .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Opens the recipe without adding a Diary entry."))
                }
                if recipes.count > Self.candidateCount {
                    Button("Other Ideas", systemImage: "arrow.triangle.2.circlepath") {
                        offset = (offset + Self.candidateCount) % recipes.count
                    }
                }
            }
        } header: {
            Text("What Sounds Good Today?")
        } footer: {
            if recipes.isEmpty {
                Text("Save a recipe to find inspiration here. A name is enough to start.")
            } else {
                Text("From your saved recipes, starting with recently updated ones.")
            }
        }
        .onChange(of: recipes.map(\.id)) {
            offset = 0
        }
    }

    private var candidates: [Recipe] {
        guard !recipes.isEmpty else {
            return []
        }
        return (0..<min(Self.candidateCount, recipes.count)).map { index in
            recipes[(offset + index) % recipes.count]
        }
    }
}
