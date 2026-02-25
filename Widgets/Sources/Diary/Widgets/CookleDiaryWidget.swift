import CookleLibrary
import SwiftUI
import WidgetKit

struct CookleDiaryWidget: Widget {
    private let kind: String = CookleWidgetKind.diary

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: DiaryConfigurationAppIntent.self,
            provider: DiaryProvider()
        ) { entry in
            CookleDiaryWidgetView(entry: entry)
                .widgetURL(CookleWidgetDeepLink.url(for: .diary))
        }
        .configurationDisplayName("Diary")
        .description("Shows diary by selection: Latest, Today, or Random.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct CookleDiaryWidgetView: View {
    let entry: DiaryEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.titleText)
                .font(titleFont)
                .foregroundStyle(.primary)
                .lineLimit(titleLineLimit)
                .minimumScaleFactor(titleScaleFactor)
                .allowsTightening(true)
                .privacySensitive()

            VStack(alignment: .leading, spacing: 6) {
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
        1
    }

    private var titleScaleFactor: CGFloat {
        isCompact ? 0.7 : 0.85
    }

    private var noteLineLimit: Int {
        isCompact ? 1 : 2
    }

    private var shouldShowNote: Bool {
        !entry.noteText.isEmpty && !isCompact
    }

    private var containerPadding: CGFloat {
        isCompact ? 10 : 12
    }
}

private struct MealRow: View {
    let title: String
    let systemImageName: String
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
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
        isCompact ? 18 : 22
    }
}
#Preview("Small", as: .systemSmall) {
    CookleDiaryWidget()
} timeline: {
    DiaryEntry(
        date: .init(timeIntervalSince1970: 1_735_000_000),
        titleText: "Today’s Meals",
        breakfastText: "Avocado toast",
        lunchText: "Chicken salad",
        dinnerText: "Salmon and rice",
        noteText: "Light seasoning and extra veggies."
    )
}

#Preview("Medium", as: .systemMedium) {
    CookleDiaryWidget()
} timeline: {
    DiaryEntry(
        date: .init(timeIntervalSince1970: 1_735_000_000),
        titleText: "Today’s Meals",
        breakfastText: "Greek yogurt with berries",
        lunchText: "Soba noodles with tofu",
        dinnerText: "Miso soup and grilled fish",
        noteText: "Hydrated well and kept portions balanced."
    )
}
