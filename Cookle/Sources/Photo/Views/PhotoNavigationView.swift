import SwiftData
import SwiftUI

struct PhotoNavigationView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var photo: Photo?
    @State private var recipe: Recipe?

    var body: some View {
        navigationView()
            .onChange(of: photo?.persistentModelID) {
                recipe = nil
            }
    }
}

private extension PhotoNavigationView {
    var regularNavigationView: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            PhotoListView(selection: $photo)
        } content: {
            if let photo {
                PhotoView(selection: $recipe)
                    .environment(photo)
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
            PhotoListView(selection: $photo)
                .navigationDestination(isPresented: $photo.isPresent()) {
                    if let photo {
                        PhotoView(selection: $recipe)
                            .environment(photo)
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
    PhotoNavigationView()
}
