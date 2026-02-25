import CookleLibrary
import SwiftData
import WidgetKit

struct DiaryProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> DiaryEntry {
        .init(
            date: .now,
            titleText: "Today",
            breakfastText: "—",
            lunchText: "—",
            dinnerText: "—",
            noteText: ""
        )
    }

    func snapshot(for configuration: DiaryConfigurationAppIntent, in _: Context) -> DiaryEntry {
        do {
            let modelContext = try ModelContainerFactory.sharedContext()
            return try makeEntry(
                date: .now,
                context: modelContext,
                mode: configuration.mode
            )
        } catch {
            return makeErrorEntry(date: .now)
        }
    }

    func timeline(for configuration: DiaryConfigurationAppIntent, in _: Context) -> Timeline<DiaryEntry> {
        let now = Date.now
        let entry: DiaryEntry = {
            do {
                let modelContext = try ModelContainerFactory.sharedContext()
                return try makeEntry(
                    date: now,
                    context: modelContext,
                    mode: configuration.mode
                )
            } catch {
                return makeErrorEntry(date: now)
            }
        }()

        let nextRefreshDate = timelineRefreshDate(date: now, mode: configuration.mode)
        return .init(entries: [entry], policy: .after(nextRefreshDate))
    }
}

private extension DiaryProvider {
    func makeEntry(date: Date, context: ModelContext, mode: DiaryWidgetMode) throws -> DiaryEntry {
        guard let diary = try diary(for: mode, date: date, context: context) else {
            return makeEmptyEntry(date: date, mode: mode)
        }
        return .init(
            date: date,
            titleText: diary.date.formatted(.dateTime.year().month().day().weekday()),
            breakfastText: mealText(for: .breakfast, from: diary),
            lunchText: mealText(for: .lunch, from: diary),
            dinnerText: mealText(for: .dinner, from: diary),
            noteText: diary.note
        )
    }

    func diary(for mode: DiaryWidgetMode, date: Date, context: ModelContext) throws -> Diary? {
        switch mode {
        case .latest:
            return try latestDiary(context: context)
        case .today:
            return try DiaryService.diary(on: date, context: context)
        case .random:
            return try randomDiary(context: context)
        }
    }

    func latestDiary(context: ModelContext) throws -> Diary? {
        let descriptor: FetchDescriptor<Diary> = .init(
            sortBy: [
                .init(\.date, order: .reverse),
                .init(\.modifiedTimestamp, order: .reverse),
                .init(\.createdTimestamp, order: .reverse)
            ]
        )
        let diaries = try context.fetch(descriptor)
        return diaries.first
    }

    func randomDiary(context: ModelContext) throws -> Diary? {
        let diaries = try context.fetch(.diaries(.all))
        return diaries.randomElement()
    }

    func timelineRefreshDate(date: Date, mode: DiaryWidgetMode) -> Date {
        switch mode {
        case .today:
            return Calendar.current.startOfDay(for: date).addingTimeInterval(24 * 60 * 60)
        case .latest,
             .random:
            if let nextDate = Calendar.current.date(byAdding: .hour, value: 6, to: date) {
                return nextDate
            }
            return date.addingTimeInterval(60 * 60)
        }
    }

    func mealText(for type: DiaryObjectType, from diary: Diary) -> String {
        let meals = diary.objects.orEmpty
            .filter { diaryObject in
                diaryObject.type == type
            }
            .sorted()
            .compactMap { diaryObject in
                diaryObject.recipe?.name
            }
        return meals.first ?? "—"
    }

    func makeEmptyEntry(date: Date, mode: DiaryWidgetMode) -> DiaryEntry {
        let titleText: String
        switch mode {
        case .today:
            titleText = date.formatted(.dateTime.year().month().day().weekday())
        case .latest,
             .random:
            titleText = "No Diaries"
        }

        return .init(
            date: date,
            titleText: titleText,
            breakfastText: "—",
            lunchText: "—",
            dinnerText: "—",
            noteText: ""
        )
    }

    func makeErrorEntry(date: Date) -> DiaryEntry {
        .init(
            date: date,
            titleText: "Error",
            breakfastText: "—",
            lunchText: "—",
            dinnerText: "—",
            noteText: ""
        )
    }
}
