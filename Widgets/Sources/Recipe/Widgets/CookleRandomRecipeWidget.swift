import CookleLibrary
import SwiftUI
import WidgetKit

struct CookleRandomRecipeWidget: Widget {
    private let kind: String = CookleWidgetKind.randomRecipe

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: RandomRecipeProvider()) { entry in
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
        }
        .configurationDisplayName("Random Recipe")
        .description("Shows a random recipe and its photo if available.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
