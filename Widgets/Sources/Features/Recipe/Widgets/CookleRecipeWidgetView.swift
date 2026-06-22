import SwiftUI
import WidgetKit

struct CookleRecipeWidgetView: View {
    private enum Layout {
        static let gradientTopOpacity = 0.0
        static let gradientBottomOpacity = 0.35
        static let singleLineLimit = 1
        static let doubleLineLimit = 2
    }

    let entry: RecipeEntry
    @Environment(\.widgetFamily)
    private var widgetFamily

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RecipeBackgroundImage(image: entry.image)

            LinearGradient(
                colors: [
                    .black.opacity(Layout.gradientTopOpacity),
                    .black.opacity(Layout.gradientBottomOpacity)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .blendMode(.multiply)

            RecipeTitleBadge(text: entry.titleText, lineLimit: titleLineLimit)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var titleLineLimit: Int {
        widgetFamily == .systemSmall ? Layout.singleLineLimit : Layout.doubleLineLimit
    }
}
