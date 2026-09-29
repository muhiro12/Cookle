@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins the matching rules that keep unchanged records out of review.
@MainActor
struct CookleDataImportMergeTests {
    typealias Store = CookleDataImportTestStore

    @Test
    func an_edited_recipe_does_not_turn_its_diary_days_into_conflicts() throws {
        let source = Store()
        let fileCurry = try source.recipe("Curry", steps: ["Old"])
        source.diary(day: 1, meals: [.init(recipe: fileCurry, type: .dinner)], note: "Good")
        source.diary(day: 2, meals: [.init(recipe: fileCurry, type: .lunch)])
        let archive = try source.archive()

        let target = Store()
        let currentCurry = try target.recipe("Curry", steps: ["Edited"])
        target.diary(day: 1, meals: [.init(recipe: currentCurry, type: .dinner)], note: "Good")
        target.diary(day: 2, meals: [.init(recipe: currentCurry, type: .lunch)])
        try target.context.save()

        let review = try target.review(of: archive)
        #expect(review.recipeConflicts.count == 1)
        #expect(review.diaryConflicts.isEmpty)
        #expect(review.unchangedDiaryCount == 2)
    }

    @Test
    func a_diary_day_with_a_different_recipe_name_is_still_a_conflict() throws {
        let source = Store()
        let fileCurry = try source.recipe("Curry")
        source.diary(day: 1, meals: [.init(recipe: fileCurry, type: .dinner)])
        let archive = try source.archive()

        let target = Store()
        let soup = try target.recipe("Soup")
        target.diary(day: 1, meals: [.init(recipe: soup, type: .dinner)])
        try target.context.save()

        #expect(try target.review(of: archive).diaryConflicts.count == 1)
    }
}
