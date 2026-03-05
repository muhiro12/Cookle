import SwiftUI
import WidgetKit

struct MealRow: View {
    private enum Layout {
        static let rowSpacing: CGFloat = 8
        static let compactIconWidth: CGFloat = 18
        static let regularIconWidth: CGFloat = 22
    }

    let title: String
    let systemImageName: String
    @Environment(\.widgetFamily)
    private var widgetFamily

    var body: some View {
        HStack(alignment: .center, spacing: Layout.rowSpacing) {
            Image(systemName: systemImageName)
                .font(iconFont)
                .foregroundStyle(.secondary)
                .frame(width: iconFrameWidth, height: iconFrameWidth, alignment: .center)
                .accessibilityHidden(true)
            Text(title)
                .font(textFont)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .privacySensitive()
            Spacer(minLength: 0)
        }
    }

    private var isCompact: Bool {
        widgetFamily == .systemSmall
    }

    private var textFont: Font {
        isCompact ? .caption : .callout
    }

    private var iconFont: Font {
        isCompact ? .caption2 : .callout
    }

    private var iconFrameWidth: CGFloat {
        isCompact ? Layout.compactIconWidth : Layout.regularIconWidth
    }
}
