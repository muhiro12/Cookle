import SwiftUI
import WidgetKit

struct RecipeBackgroundImage: View {
    private enum Layout {
        static let topGradientOpacity = 0.12
        static let middleGradientOpacity = 0.08
        static let topGradientLocation = 0.0
        static let middleGradientLocation = 0.5
        static let bottomGradientLocation = 1.0
        static let compactIconSize: CGFloat = 36
        static let regularIconSize: CGFloat = 44
    }

    let image: UIImage?
    @Environment(\.widgetFamily)
    private var widgetFamily

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel(Text("Recipe Photo"))
                    .clipped()
                    .privacySensitive()
            } else {
                placeholderBackground
            }
        }
    }

    private var iconSize: CGFloat {
        widgetFamily == .systemSmall ? Layout.compactIconSize : Layout.regularIconSize
    }

    private var placeholderBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(
                        color: .gray.opacity(Layout.topGradientOpacity),
                        location: Layout.topGradientLocation
                    ),
                    .init(
                        color: .gray.opacity(Layout.middleGradientOpacity),
                        location: Layout.middleGradientLocation
                    ),
                    .init(
                        color: .gray.opacity(Layout.topGradientOpacity),
                        location: Layout.bottomGradientLocation
                    )
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}
