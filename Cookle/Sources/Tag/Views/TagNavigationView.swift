import SwiftData
import SwiftUI

struct TagNavigationView<T: Tag>: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var tag: T?
    @State private var recipe: Recipe?

    var body: some View {
        navigationView()
            .onChange(of: tag?.persistentModelID) {
                recipe = nil
            }
    }
}

private extension TagNavigationView {
    var regularNavigationView: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            TagListView<T>(selection: $tag)
        } content: {
            if let tag {
                TagView<T>(selection: $recipe)
                    .environment(tag)
            }
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            }
        }
    }

    var compactNavigationView: some View {
        NavigationStack {
            TagListView<T>(selection: $tag)
                .listStyle(.insetGrouped)
                .navigationDestination(isPresented: $tag.isPresent()) {
                    if let tag {
                        TagView<T>(selection: $recipe)
                            .environment(tag)
                    }
                }
                .navigationDestination(isPresented: $recipe.isPresent()) {
                    if let recipe {
                        RecipeView()
                            .environment(recipe)
                    }
                }
        }
    }

    @ViewBuilder
    func navigationView() -> some View {
        if horizontalSizeClass == .regular {
            regularNavigationView
        } else {
            compactNavigationView
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    TagNavigationView<Ingredient>()
}
