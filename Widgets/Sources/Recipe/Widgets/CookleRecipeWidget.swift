import CookleLibrary
import SwiftUI
import WidgetKit

struct CookleRecipeWidget: Widget {
    private let kind: String = CookleWidgetKind.recipe

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: RecipeConfigurationAppIntent.self,
            provider: RecipeProvider()
        ) { entry in
            CookleRecipeWidgetView(entry: entry)
                .widgetURL(entry.deepLinkURL)
        }
        .configurationDisplayName("Recipe")
        .description("Shows a recipe by selection: Latest, Last Opened, or Random.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview("Small", as: .systemSmall) {
    CookleRecipeWidget()
} timeline: {
    let image: UIImage? = nil
    let entry: RecipeEntry = .init(
        date: .init(timeIntervalSince1970: 1_735_000_000),
        titleText: "Herb Omelette",
        image: image,
        deepLinkURL: nil
    )
    entry
}

#Preview("Medium", as: .systemMedium) {
    CookleRecipeWidget()
} timeline: {
    let image: UIImage? = nil
    let entry: RecipeEntry = .init(
        date: .init(timeIntervalSince1970: 1_735_000_000),
        titleText: "Vegetable Curry with Coconut Milk",
        image: image,
        deepLinkURL: nil
    )
    entry
}
