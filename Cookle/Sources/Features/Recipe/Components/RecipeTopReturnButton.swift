import SwiftUI

struct RecipeTopReturnButton: View {
    let target: RecipeTopReturnTarget
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label {
                VStack(alignment: .leading) {
                    target.title
                    Text(target.recipeName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } icon: {
                Image(systemName: target.iconSystemName)
                    .accessibilityHidden(true)
            }
            .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text("\(target.accessibilityTitle): \(target.recipeName)")
        )
        .accessibilityHint(Text("Opens the recipe."))
    }
}

#Preview("Active Session") {
    NavigationStack {
        List {
            Section {
                RecipeTopReturnButton(
                    target: .init(
                        kind: .activeCookingSession,
                        recipeName: "Spaghetti Carbonara",
                        recipeStableIdentifier: "active-recipe"
                    )
                ) {
                    // Preview only.
                }
            }
        }
        .navigationTitle("Recipes")
    }
}

private extension RecipeTopReturnTarget {
    var accessibilityTitle: String {
        switch kind {
        case .activeCookingSession:
            return "Resume cooking"
        case .lastOpenedRecipe:
            return "Back to last opened recipe"
        }
    }
}

#Preview("Last Opened") {
    NavigationStack {
        List {
            Section {
                RecipeTopReturnButton(
                    target: .init(
                        kind: .lastOpenedRecipe,
                        recipeName: "Beef Stew",
                        recipeStableIdentifier: "last-opened-recipe"
                    )
                ) {
                    // Preview only.
                }
            }
        }
        .navigationTitle("Recipes")
    }
}
