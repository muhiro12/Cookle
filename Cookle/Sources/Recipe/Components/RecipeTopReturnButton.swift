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
