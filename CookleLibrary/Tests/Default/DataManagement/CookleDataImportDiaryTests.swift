@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins how an export file merges diary days and how stale approvals are refused.
@MainActor
struct CookleDataImportDiaryTests {
    typealias Store = CookleDataImportTestStore

    struct Fixture {
        let archive: CookleDataArchive
        let target: Store
        let conflictDiary: Diary
        let untouchedDiary: Diary
    }

    @Test
    func keeping_the_current_day_leaves_it_unchanged() throws {
        let fixture = try makeSameDayFixture()
        let review = try fixture.target.review(of: fixture.archive)
        let conflict = try #require(review.diaryConflicts.first)

        let summary = try apply(fixture, review: review, choice: .keepCurrent, for: conflict)

        #expect(summary.keptDiaryCount == 1)
        #expect(fixture.conflictDiary.note == "Current note")
        #expect(fixture.conflictDiary.objects?.count == 1)
    }

    @Test
    func using_the_backup_replaces_only_that_day() throws {
        let fixture = try makeSameDayFixture()
        let review = try fixture.target.review(of: fixture.archive)
        let conflict = try #require(review.diaryConflicts.first)
        #expect(conflict.backup.meals.map(\.recipeName) == ["Toast", "Toast"])
        #expect(conflict.current.meals.map(\.recipeName) == ["Toast"])

        let summary = try apply(fixture, review: review, choice: .useBackup, for: conflict)

        #expect(summary.updatedDiaryCount == 1)
        #expect(fixture.conflictDiary.note == "Backup note")
        #expect(fixture.conflictDiary.objects?.count == 2)
        #expect(fixture.untouchedDiary.note == "Other day")
        #expect(try fixture.target.count(Diary.self) == 2)
    }

    @Test
    func combining_keeps_repeats_once_and_joins_differing_notes() throws {
        let fixture = try makeSameDayFixture()
        let review = try fixture.target.review(of: fixture.archive)
        let conflict = try #require(review.diaryConflicts.first)

        let summary = try apply(fixture, review: review, choice: .combine, for: conflict)

        #expect(summary.combinedDiaryCount == 1)
        // Current has one breakfast toast, backup two: the maximum, two, is kept.
        #expect(fixture.conflictDiary.objects?.count == 2)
        #expect(fixture.conflictDiary.note == "Current note\n\n---\n\nBackup note")
        #expect(try fixture.target.count(Recipe.self) == 1)
    }

    @Test
    func a_day_with_two_current_diaries_is_a_prerequisite_error() throws {
        let source = Store()
        source.diary(day: 1, meals: [], note: "Backup")
        let archive = try source.archive()
        let target = Store()
        target.diary(day: 1, meals: [], note: "One")
        target.diary(day: 1, meals: [], note: "Two")
        try target.context.save()

        #expect(throws: CookleDataImportError.duplicateCurrentDiaryDays) {
            try target.review(of: archive)
        }
    }

    @Test
    func a_change_after_review_refuses_the_old_approval_and_keeps_unaffected_choices() throws {
        let fixture = try makeSameDayFixture()
        let review = try fixture.target.review(of: fixture.archive)
        let conflict = try #require(review.diaryConflicts.first)
        let selections = CookleDataImportSelections(diaryChoices: [conflict.id: .useBackup])

        fixture.conflictDiary.update(
            content: .init(
                date: fixture.conflictDiary.date,
                objects: fixture.conflictDiary.objects ?? [],
                note: "Edited"
            )
        )
        try fixture.target.context.save()

        var refreshed: CookleDataImportReview?
        do {
            _ = try DataMaintenanceOperations.importArchive(
                fixture.archive,
                review: review,
                selections: selections,
                context: fixture.target.context
            )
        } catch CookleDataImportError.reviewChanged(let currentReview) {
            refreshed = currentReview
        }
        let currentReview = try #require(refreshed)
        #expect(fixture.target.context.hasChanges == false)
        #expect(fixture.conflictDiary.note == "Edited")
        #expect(currentReview.diaryConflicts.first?.current.note == "Edited")
        // The conflict changed, so its choice must be made again.
        #expect(selections.retainingUnchangedChoices(from: review, in: currentReview).diaryChoices.isEmpty)
        #expect(selections.retainingUnchangedChoices(from: review, in: review) == selections)
    }

    @Test
    func a_failed_save_rolls_back_every_change() throws {
        let fixture = try makeSameDayFixture()
        let review = try fixture.target.review(of: fixture.archive)
        let conflict = try #require(review.diaryConflicts.first)

        #expect(throws: TestSaveError.self) {
            try CookleDataImportService.apply(
                fixture.archive,
                review: review,
                selections: .init(diaryChoices: [conflict.id: .useBackup]),
                context: fixture.target.context
            ) { _ in
                throw TestSaveError()
            }
        }

        #expect(fixture.target.context.hasChanges == false)
        #expect(fixture.conflictDiary.note == "Current note")
        #expect(try fixture.target.count(Diary.self) == 2)
        #expect(try fixture.target.count(DiaryObject.self) == 2)
    }

    @Test
    func a_merged_store_reopens_with_every_record() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("store.sqlite")
        let source = Store()
        let toast = try source.recipe("Toast", photos: [Store.photo("toast")])
        source.diary(day: 1, meals: [.init(recipe: toast, type: .breakfast)])
        let archive = try source.archive()
        let writer = Store(context: try makeDiskContext(at: url))
        try writer.recipe("Soup")
        try writer.context.save()

        let review = try writer.review(of: archive)
        _ = try DataMaintenanceOperations.importArchive(
            archive,
            review: review,
            selections: .init(),
            context: writer.context
        )

        let reopened = Store(context: try makeDiskContext(at: url))
        #expect(try reopened.count(Recipe.self) == 2)
        #expect(try reopened.recipes(named: "Toast").first?.orderedPhotos.map(\.data) == [Data("toast".utf8)])
        #expect(try reopened.count(DiaryObject.self) == 1)
    }
}

private extension CookleDataImportDiaryTests {
    enum Days {
        static let otherDay = 2
    }

    struct TestSaveError: Error {}

    /// Current and backup share day 1 with different meals and notes; day 2 exists only in current.
    func makeSameDayFixture() throws -> Fixture {
        let source = Store()
        let backupToast = try source.recipe("Toast")
        source.diary(
            day: 1,
            meals: [.init(recipe: backupToast, type: .breakfast), .init(recipe: backupToast, type: .breakfast)],
            note: "Backup note"
        )
        let archive = try source.archive()
        let target = Store()
        let toast = try target.recipe("Toast")
        let conflictDiary = target.diary(day: 1, meals: [.init(recipe: toast, type: .breakfast)], note: "Current note")
        let untouchedDiary = target.diary(
            day: Days.otherDay,
            meals: [.init(recipe: toast, type: .dinner)],
            note: "Other day"
        )
        try target.context.save()
        return .init(archive: archive, target: target, conflictDiary: conflictDiary, untouchedDiary: untouchedDiary)
    }

    func apply(
        _ fixture: Fixture,
        review: CookleDataImportReview,
        choice: CookleDataDiaryImportChoice,
        for conflict: CookleDataImportReview.DiaryConflict
    ) throws -> CookleDataImportSummary {
        try DataMaintenanceOperations.importArchive(
            fixture.archive,
            review: review,
            selections: .init(diaryChoices: [conflict.id: choice]),
            context: fixture.target.context
        )
    }

    func makeDiskContext(at url: URL) throws -> ModelContext {
        let container = try ModelContainerFactory.makeModelContainer(url: url, cloudKitDatabase: .none)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }
}
