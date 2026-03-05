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
                .widgetURL(entry.deepLinkURL)
        }
        .configurationDisplayName("Diary")
        .description("Shows diary by selection: Latest, Today, or Random.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
        noteText: "Light seasoning and extra veggies.",
        deepLinkURL: nil
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
        noteText: "Hydrated well and kept portions balanced.",
        deepLinkURL: nil
    )
}
