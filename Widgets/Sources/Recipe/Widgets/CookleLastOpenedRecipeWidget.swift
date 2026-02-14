import CookleLibrary
import SwiftUI
import WidgetKit

struct CookleLastOpenedRecipeWidget: Widget {
    private let kind: String = CookleWidgetKind.lastOpenedRecipe

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: LastOpenedRecipeProvider()) { entry in
            ZStack(alignment: .bottomLeading) {
                if let uiImage = entry.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .privacySensitive()
                }
                Text(entry.titleText)
                    .privacySensitive()
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(8)
                    .background(.thinMaterial, in: .rect(cornerRadius: 8))
                    .padding(6)
            }
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(CookleWidgetDeepLink.url(for: .recipe))
        }
        .configurationDisplayName("Last Opened Recipe")
        .description("Shows the recipe you opened most recently.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
