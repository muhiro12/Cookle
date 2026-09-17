import MHUI
import SwiftUI

struct SearchResultsView: View {
    let recipes: [Recipe]
    @Binding var selection: Recipe?

    var body: some View {
        MHGroupedRows {
            ForEach(recipes) { recipe in
                Button {
                    $selection.cookleSelectForNavigation(recipe)
                } label: {
                    RecipeLabel()
                        .labelStyle(.titleAndLargeIcon)
                        .environment(recipe)
                        .cookleButtonRowContent()
                }
                .buttonStyle(.plain)
            }
        }
        .mhSurfaceInset()
        .mhSurface()
        .mhScreen()
    }
}
