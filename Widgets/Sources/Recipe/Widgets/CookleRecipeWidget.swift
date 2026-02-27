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

private struct CookleRecipeWidgetView: View {
    let entry: RecipeEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RecipeBackgroundImage(image: entry.image)

            LinearGradient(
                colors: [
                    .black.opacity(0.0),
                    .black.opacity(0.35)
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
        widgetFamily == .systemSmall ? 1 : 2
    }
}

private struct RecipeBackgroundImage: View {
    let image: UIImage?
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .privacySensitive()
            } else {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .gray.opacity(0.12), location: 0.0),
                            .init(color: .gray.opacity(0.08), location: 0.5),
                            .init(color: .gray.opacity(0.12), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: iconSize, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var iconSize: CGFloat {
        widgetFamily == .systemSmall ? 36 : 44
    }
}

private struct RecipeTitleBadge: View {
    let text: String
    let lineLimit: Int

    var body: some View {
        Text(text)
            .privacySensitive()
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.85)
            .padding(10)
            .background(.thinMaterial, in: .rect(cornerRadius: 10))
            .padding(8)
            .padding(.bottom, 4)
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
