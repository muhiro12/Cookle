import CookleLibrary
import SwiftUI
import WidgetKit

struct CookleTodayDiaryWidget: Widget {
    private let kind: String = CookleWidgetKind.todayDiary

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: TodayDiaryProvider()) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.titleText)
                    .font(.headline)
                HStack {
                    Label(entry.breakfastText, systemImage: "sunrise.fill")
                        .privacySensitive()
                    Spacer()
                }
                .font(.caption)
                HStack {
                    Label(entry.lunchText, systemImage: "sun.max.fill")
                        .privacySensitive()
                    Spacer()
                }
                .font(.caption)
                HStack {
                    Label(entry.dinnerText, systemImage: "moon.fill")
                        .privacySensitive()
                    Spacer()
                }
                .font(.caption)
                if !entry.noteText.isEmpty {
                    Divider()
                    Text(entry.noteText)
                        .privacySensitive()
                        .font(.caption2)
                        .lineLimit(2)
                }
            }
            .padding(8)
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today’s Meals")
        .description("Shows today’s breakfast, lunch and dinner from your diary.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
