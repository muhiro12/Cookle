import SwiftUI
import WidgetKit

struct CookleTodayDiaryWidget: Widget {
    let kind: String = "CookleTodayDiaryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: TodayDiaryProvider()) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.titleText)
                    .font(.headline)
                HStack {
                    Label(entry.breakfastText, systemImage: "sunrise.fill")
                    Spacer()
                }
                .font(.caption)
                HStack {
                    Label(entry.lunchText, systemImage: "sun.max.fill")
                    Spacer()
                }
                .font(.caption)
                HStack {
                    Label(entry.dinnerText, systemImage: "moon.fill")
                    Spacer()
                }
                .font(.caption)
                if !entry.noteText.isEmpty {
                    Divider()
                    Text(entry.noteText)
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
