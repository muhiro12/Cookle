import SwiftUI
import WidgetKit

struct CookleRandomRecipeWidget: Widget {
    let kind: String = "CookleRandomRecipeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: RandomRecipeProvider()) { entry in
            ZStack(alignment: .bottomLeading) {
                if let uiImage = entry.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                }
                Text(entry.titleText)
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
