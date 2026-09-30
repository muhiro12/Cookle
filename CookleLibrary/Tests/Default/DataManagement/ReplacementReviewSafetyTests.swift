@testable import CookleLibrary
import Foundation
import Testing

@MainActor
struct ReplacementReviewSafetyTests {
    private typealias Store = CookleDataImportTestStore

    @Test
    func unchanged_complete_data_can_be_replaced_after_review() throws {
        let source = Store()
        try source.recipe("Imported")
        let archive = try source.archive()
        let target = Store()
        try target.recipe("Current")
        try target.context.save()
        let review = try DataMaintenanceOperations.replacementReview(for: archive, context: target.context)

        _ = try DataMaintenanceOperations.replaceAllData(with: archive, review: review, context: target.context)

        #expect(try target.recipes(named: "Current").isEmpty)
        #expect(try target.recipes(named: "Imported").count == 1)
    }

    @Test
    func changed_data_absent_from_the_file_requires_a_new_replacement_review() throws {
        let source = Store()
        try source.recipe("Imported")
        let archive = try source.archive()
        let target = Store()
        let current = try target.recipe("Current", note: "Before")
        try target.context.save()
        let review = try DataMaintenanceOperations.replacementReview(for: archive, context: target.context)
        current.update(content: .init(name: current.name, note: "Edited after review"))
        try target.context.save()

        #expect(throws: CookleDataImportError.replacementReviewChanged) {
            try DataMaintenanceOperations.replaceAllData(with: archive, review: review, context: target.context)
        }
        #expect(current.note == "Edited after review")
        #expect(try target.recipes(named: "Imported").isEmpty)
        #expect(target.context.hasChanges == false)

        let refreshed = try DataMaintenanceOperations.replacementReview(for: archive, context: target.context)
        _ = try DataMaintenanceOperations.replaceAllData(with: archive, review: refreshed, context: target.context)
        #expect(try target.recipes(named: "Imported").count == 1)
    }

    @Test
    func adding_a_standalone_tag_invalidates_replacement_approval() throws {
        let source = Store()
        let archive = try source.archive()
        let target = Store()
        let review = try DataMaintenanceOperations.replacementReview(for: archive, context: target.context)
        let ingredient = try Ingredient.create(context: target.context, value: "Standalone")
        try target.context.save()

        #expect(throws: CookleDataImportError.replacementReviewChanged) {
            try DataMaintenanceOperations.replaceAllData(with: archive, review: review, context: target.context)
        }
        #expect(ingredient.value == "Standalone")
        #expect(try target.count(Ingredient.self) == 1)
    }

    @Test
    func a_different_file_cannot_reuse_replacement_approval() throws {
        let source = Store()
        try source.recipe("Reviewed")
        let archive = try source.archive()
        let target = Store()
        let review = try DataMaintenanceOperations.replacementReview(for: archive, context: target.context)
        try source.recipe("Added after review")
        let changed = try source.archive()

        #expect(throws: CookleDataImportError.replacementReviewChanged) {
            try DataMaintenanceOperations.replaceAllData(with: changed, review: review, context: target.context)
        }
        #expect(try target.count(Recipe.self) == .zero)
    }

    @Test(arguments: [false, true])
    func imports_preserve_an_unrelated_unsaved_edit(replacesAllData: Bool) throws {
        let source = Store()
        try source.recipe("Imported")
        let archive = try source.archive()
        let target = Store()
        let current = try target.recipe("Current", note: "Saved")
        try target.context.save()
        let mergeReview = try target.review(of: archive)
        current.update(content: .init(name: current.name, note: "Unsaved edit"))

        #expect(throws: CookleDataImportError.pendingChanges) {
            if replacesAllData {
                _ = try DataMaintenanceOperations.replaceAllData(with: archive, context: target.context)
            } else {
                _ = try DataMaintenanceOperations.importArchive(
                    archive, review: mergeReview, selections: .init(), context: target.context
                )
            }
        }
        #expect(current.note == "Unsaved edit")
        #expect(target.context.hasChanges)
        #expect(try target.recipes(named: "Imported").isEmpty)
        target.context.rollback()
        #expect(current.note == "Saved")
    }
}
