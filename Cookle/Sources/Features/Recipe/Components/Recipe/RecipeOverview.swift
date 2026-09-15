import MHUI
import SwiftUI

struct RecipeOverview: View {
    @Environment(\.mhTheme)
    private var theme
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let servingSize: Int
    let cookingTime: Int

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.content))
            : AnyLayout(HStackLayout(alignment: .top, spacing: theme.spacing.section))

        if servingSize != .zero || cookingTime != .zero {
            layout {
                if servingSize != .zero {
                    RecipeOverviewValue(
                        title: "Serving Size",
                        value: Text(servingSize, format: .number)
                    )
                }
                if cookingTime != .zero {
                    RecipeOverviewValue(
                        title: "Cooking Time",
                        value: Text("\(cookingTime) min")
                    )
                }
            }
        }
    }
}
