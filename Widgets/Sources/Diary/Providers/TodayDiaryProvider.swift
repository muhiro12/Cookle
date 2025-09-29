import CookleLibrary
import SwiftData
import SwiftUI
import WidgetKit

struct TodayDiaryProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> TodayDiaryEntry {
        .init(
            date: .now,
            titleText: "Today",
            breakfastText: "—",
            lunchText: "—",
            dinnerText: "—",
            noteText: ""
        )
    }

    func snapshot(for _: ConfigurationAppIntent, in _: Context) -> TodayDiaryEntry {
        makeEntry(now: .now)
    }

    func timeline(for _: ConfigurationAppIntent, in _: Context) -> Timeline<TodayDiaryEntry> {
        let now = Date.now
        var entries: [TodayDiaryEntry] = .init()
        for hour in 0 ..< 5 {
            if let date = Calendar.current.date(byAdding: .hour, value: hour, to: now) {
                let entry = makeEntry(now: date)
                entries.append(entry)
            }
        }
        return .init(entries: entries, policy: .atEnd)
    }

    private func makeEntry(now: Date) -> TodayDiaryEntry {
        do {
            let context = try ModelContainerFactory.sharedContext()
            if let diary = try DiaryService.diary(on: now, context: context) {
                let titleText = diary.date.formatted(.dateTime.year().month().day().weekday())
                let breakfasts = diary.objects.orEmpty.filter { $0.type == .breakfast }.sorted().compactMap { $0.recipe?.name }
                let lunches = diary.objects.orEmpty.filter { $0.type == .lunch }.sorted().compactMap { $0.recipe?.name }
                let dinners = diary.objects.orEmpty.filter { $0.type == .dinner }.sorted().compactMap { $0.recipe?.name }
                return .init(
                    date: now,
                    titleText: titleText,
                    breakfastText: breakfasts.first ?? "—",
                    lunchText: lunches.first ?? "—",
                    dinnerText: dinners.first ?? "—",
                    noteText: diary.note
                )
            }
            return .init(
                date: now,
                titleText: now.formatted(.dateTime.year().month().day().weekday()),
                breakfastText: "—",
                lunchText: "—",
                dinnerText: "—",
                noteText: ""
            )
        } catch {
            return .init(
                date: now,
                titleText: "Error",
                breakfastText: "—",
                lunchText: "—",
                dinnerText: "—",
                noteText: ""
            )
        }
    }
}
