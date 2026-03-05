import SwiftUI
import WidgetKit

struct CookleDiaryWidgetView: View {
    private enum Layout {
        static let mealSpacing: CGFloat = 8
        static let noteSpacing: CGFloat = 6
        static let compactTitleScaleFactor: CGFloat = 0.7
        static let regularTitleScaleFactor: CGFloat = 0.85
        static let singleLineLimit = 1
        static let doubleLineLimit = 2
        static let compactPadding: CGFloat = 10
        static let regularPadding: CGFloat = 12
    }

    let entry: DiaryEntry
    @Environment(\.widgetFamily)
    private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.mealSpacing) {
            Text(entry.titleText)
                .font(titleFont)
                .foregroundStyle(.primary)
                .lineLimit(titleLineLimit)
                .minimumScaleFactor(titleScaleFactor)
                .allowsTightening(true)
                .privacySensitive()

            VStack(alignment: .leading, spacing: Layout.noteSpacing) {
                MealRow(
                    title: entry.breakfastText,
                    systemImageName: "sunrise.fill"
                )
                MealRow(
                    title: entry.lunchText,
                    systemImageName: "sun.max.fill"
                )
                MealRow(
                    title: entry.dinnerText,
                    systemImageName: "moon.fill"
                )
            }

            if shouldShowNote {
                Divider()
                Text(entry.noteText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(noteLineLimit)
                    .privacySensitive()
            }
        }
        .padding(containerPadding)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var isCompact: Bool {
        widgetFamily == .systemSmall
    }

    private var titleFont: Font {
        isCompact ? .headline : .title3
    }

    private var titleLineLimit: Int {
        Layout.singleLineLimit
    }

    private var titleScaleFactor: CGFloat {
        isCompact ? Layout.compactTitleScaleFactor : Layout.regularTitleScaleFactor
    }

    private var noteLineLimit: Int {
        isCompact ? Layout.singleLineLimit : Layout.doubleLineLimit
    }

    private var shouldShowNote: Bool {
        !entry.noteText.isEmpty && !isCompact
    }

    private var containerPadding: CGFloat {
        isCompact ? Layout.compactPadding : Layout.regularPadding
    }
}
