import Foundation
import SwiftData

/// Internal compatibility collaborator for legacy same-day diary rows.
@preconcurrency
@MainActor
enum DiaryDuplicateDayService {
    static func report(
        context: ModelContext,
        calendar: Calendar
    ) throws -> DiaryDayConflictReport {
        let groups = try duplicateDayGroups(
            context: context,
            calendar: calendar
        )
        return .init(
            conflictingDayCount: groups.count,
            excessDiaryCount: groups.reduce(.zero) { count, group in
                count + group.diaries.count - 1
            }
        )
    }

    static func repairWithOutcome(
        context: ModelContext,
        calendar: Calendar
    ) throws -> MutationOutcome<DiaryDayRepairSummary> {
        let groups = try duplicateDayGroups(
            context: context,
            calendar: calendar
        )
        let plans = try groups.map(makeRepairPlan)
        var removedDiaryCount = 0

        for plan in plans {
            apply(
                plan,
                context: context
            )
            removedDiaryCount += plan.diaries.count - 1
        }

        return .init(
            value: .init(
                mergedDayCount: groups.count,
                removedDiaryCount: removedDiaryCount
            ),
            effects: groups.isEmpty ? [] : [.diaryDataChanged]
        )
    }

    static func orderedDiaries(
        _ diaries: [Diary]
    ) -> [Diary] {
        diaries.sorted { lhs, rhs in
            if lhs.date != rhs.date {
                return lhs.date > rhs.date
            }
            if lhs.modifiedTimestamp != rhs.modifiedTimestamp {
                return lhs.modifiedTimestamp > rhs.modifiedTimestamp
            }
            if lhs.createdTimestamp != rhs.createdTimestamp {
                return lhs.createdTimestamp > rhs.createdTimestamp
            }
            return stableIdentifier(for: lhs) > stableIdentifier(for: rhs)
        }
    }
}

private extension DiaryDuplicateDayService {
    enum RepairError: LocalizedError {
        case invalidDiaryObject

        var errorDescription: String? {
            "A duplicate diary contains an invalid meal row and could not be merged safely."
        }
    }

    struct DuplicateDayGroup {
        let day: Date
        let diaries: [Diary]
    }

    struct MealRowKey: Hashable {
        let typeID: String
        let recipeID: String
    }

    struct MealRowSource {
        let recipe: Recipe
        let type: DiaryObjectType
        let timestamps: PersistentTimestamps
    }

    struct RepairPlan {
        let diaries: [Diary]
        let mealRowSources: [MealRowSource]
        let note: String
    }

    static func duplicateDayGroups(
        context: ModelContext,
        calendar: Calendar
    ) throws -> [DuplicateDayGroup] {
        let diaries = try context.fetch(.diaries(.all))
        return Dictionary(grouping: diaries) { diary in
            calendar.startOfDay(for: diary.date)
        }
        .compactMap { day, diaries in
            guard diaries.count > 1 else {
                return nil
            }
            return .init(
                day: day,
                diaries: orderedDiaries(diaries)
            )
        }
        .sorted { lhs, rhs in
            lhs.day < rhs.day
        }
    }

    static func makeRepairPlan(
        for group: DuplicateDayGroup
    ) throws -> RepairPlan {
        .init(
            diaries: group.diaries,
            mealRowSources: try mealRowSources(from: group.diaries),
            note: mergedNote(from: group.diaries)
        )
    }

    static func apply(
        _ plan: RepairPlan,
        context: ModelContext
    ) {
        guard let canonicalDiary = plan.diaries.first else {
            return
        }

        let mealRows = restoredMealRows(
            from: plan.mealRowSources,
            context: context
        )
        let previousCanonicalObjects = canonicalDiary.objects ?? []
        canonicalDiary.update(
            content: .init(
                date: canonicalDiary.date,
                objects: mealRows,
                note: plan.note
            )
        )
        previousCanonicalObjects.forEach(context.delete)
        plan.diaries.dropFirst().forEach(context.delete)
    }

    static func restoredMealRows(
        from sources: [MealRowSource],
        context: ModelContext
    ) -> [DiaryObject] {
        var nextOrderByType = [String: Int]()
        return sources.map { source in
            let nextOrder = nextOrderByType[
                source.type.id,
                default: .zero
            ] + 1
            nextOrderByType[source.type.id] = nextOrder
            return DiaryObject.restore(
                context: context,
                recipe: source.recipe,
                type: source.type,
                order: nextOrder,
                timestamps: source.timestamps
            )
        }
    }

    static func mealRowSources(
        from diaries: [Diary]
    ) throws -> [MealRowSource] {
        var seenRows = Set<MealRowKey>()
        var sources = [MealRowSource]()

        for diary in diaries {
            for type in DiaryObjectType.allCases {
                for object in try orderedObjects(in: diary, type: type) {
                    guard let recipe = object.recipe else {
                        throw RepairError.invalidDiaryObject
                    }
                    let key: MealRowKey = .init(
                        typeID: type.id,
                        recipeID: stableIdentifier(for: recipe)
                    )
                    guard seenRows.insert(key).inserted else {
                        continue
                    }
                    sources.append(
                        .init(
                            recipe: recipe,
                            type: type,
                            timestamps: .init(
                                created: object.createdTimestamp,
                                modified: object.modifiedTimestamp
                            )
                        )
                    )
                }
            }
        }
        return sources
    }

    static func orderedObjects(
        in diary: Diary,
        type: DiaryObjectType
    ) throws -> [DiaryObject] {
        let objects = diary.objects ?? []
        guard objects.allSatisfy({ object in
            object.type != nil && object.recipe != nil
        }) else {
            throw RepairError.invalidDiaryObject
        }
        return objects
            .filter { object in
                object.type == type
            }
            .sorted { lhs, rhs in
                if lhs.order != rhs.order {
                    return lhs.order < rhs.order
                }
                if lhs.createdTimestamp != rhs.createdTimestamp {
                    return lhs.createdTimestamp < rhs.createdTimestamp
                }
                return stableIdentifier(for: lhs) < stableIdentifier(for: rhs)
            }
    }

    static func mergedNote(
        from diaries: [Diary]
    ) -> String {
        var seenNotes = Set<String>()
        return diaries
            .map(\.note)
            .filter { note in
                !note.isEmpty && seenNotes.insert(note).inserted
            }
            .joined(separator: "\n\n")
    }

    static func stableIdentifier<Model>(
        for model: Model
    ) -> String where Model: PersistentModel {
        PersistentModelStableIdentifierCodec.stableIdentifier(
            for: model
        )
    }
}
