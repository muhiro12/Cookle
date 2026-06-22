import SwiftData
import SwiftUI

struct PhotoNavigationView: View {
    @Binding private var photo: Photo?
    @State private var recipe: Recipe?
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(.all),
            preferredCompactColumn: $preferredCompactColumn
        ) {
            PhotoListView(selection: $photo)
        } content: {
            if let photo {
                PhotoView(
                    photoSelection: $photo,
                    recipeSelection: $recipe
                )
                .environment(photo)
            }
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            }
        }
        .task {
            applyInitialCompactColumnIfNeeded()
        }
        .onChange(of: photo?.persistentModelID) {
            recipe = nil
            syncPreferredCompactColumn()
        }
        .onChange(of: recipe?.persistentModelID) {
            syncPreferredCompactColumn()
        }
    }

    init(selection: Binding<Photo?> = .constant(nil)) {
        _photo = selection
    }
}

private extension PhotoNavigationView {
    func applyInitialCompactColumnIfNeeded() {
        guard !hasAppliedInitialCompactColumn else {
            return
        }

        hasAppliedInitialCompactColumn = true
        syncPreferredCompactColumn()
    }

    func syncPreferredCompactColumn() {
        preferredCompactColumn = CompactSplitColumnPolicy.threeColumn(
            hasContentSelection: photo != nil,
            hasDetailSelection: recipe != nil
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    PhotoNavigationView()
}
