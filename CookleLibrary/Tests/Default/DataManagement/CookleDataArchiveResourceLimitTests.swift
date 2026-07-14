@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct CookleDataArchiveResourceLimitTests {
    private typealias Support = ArchiveResourceLimitTestSupport

    @Test
    func validatedArchive_throws_when_top_level_count_exceeds_limit() {
        let archive = Support.makeArchive(
            ingredients: [
                Support.makeIngredient(
                    id: "ingredient-1"
                ),
                Support.makeIngredient(
                    id: "ingredient-2"
                )
            ]
        )

        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: Support.encodedData(
                    from: archive
                ),
                limits: Support.makeLimits(
                    maximumTopLevelRecordCountPerCategory: 1
                )
            )
            Issue.record("Expected top-level record validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceCountExceeded(
            category,
            actualCount,
            maximumCount
        ) {
            #expect(category == .ingredientRecords)
            #expect(actualCount == 2)
            #expect(maximumCount == 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_throws_when_identifier_utf8_size_exceeds_limit() {
        let archive = Support.makeArchive(
            ingredients: [
                Support.makeIngredient(
                    id: "abc"
                )
            ]
        )

        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: Support.encodedData(
                    from: archive
                ),
                limits: Support.makeLimits(
                    maximumIdentifierByteCount: 2
                )
            )
            Issue.record("Expected identifier byte validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .identifier)
            #expect(actualByteCount == 3)
            #expect(maximumByteCount == 2)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_throws_when_text_utf8_size_exceeds_limit() {
        let archive = Support.makeArchive(
            ingredients: [
                Support.makeIngredient(
                    value: "é"
                )
            ]
        )

        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: Support.encodedData(
                    from: archive
                ),
                limits: Support.makeLimits(
                    maximumTextByteCount: 1
                )
            )
            Issue.record("Expected text byte validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .text)
            #expect(actualByteCount == 2)
            #expect(maximumByteCount == 1)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_throws_when_photo_size_exceeds_limit() {
        let archive = Support.makeArchive(
            photos: [
                Support.makePhoto(
                    data: .init(repeating: 0, count: 4)
                )
            ]
        )

        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: Support.encodedData(
                    from: archive
                ),
                limits: Support.makeLimits(
                    maximumPhotoByteCount: 3
                )
            )
            Issue.record("Expected individual photo byte validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .photoData)
            #expect(actualByteCount == 4)
            #expect(maximumByteCount == 3)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func validatedArchive_throws_when_aggregate_photo_size_exceeds_limit() {
        let archive = Support.makeArchive(
            photos: [
                Support.makePhoto(
                    data: .init(repeating: 0, count: 3),
                    id: "photo-1"
                ),
                Support.makePhoto(
                    data: .init(repeating: 1, count: 3),
                    id: "photo-2"
                )
            ]
        )

        do {
            _ = try CookleDataArchiveService.validatedArchive(
                from: Support.encodedData(
                    from: archive
                ),
                limits: Support.makeLimits(
                    maximumPhotoByteCount: 3,
                    maximumAggregatePhotoByteCount: 5
                )
            )
            Issue.record("Expected aggregate photo byte validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceByteCountExceeded(
            category,
            actualByteCount,
            maximumByteCount
        ) {
            #expect(category == .aggregatePhotoData)
            #expect(actualByteCount == 6)
            #expect(maximumByteCount == 5)
        } catch {
            Issue.record(error)
        }
    }

    @Test
    func restore_rejects_aggregate_nested_count_before_deleting_current_data() throws {
        let context = makeTestContext()
        _ = Recipe.create(
            context: context,
            content: .init(
                name: "Existing",
                photos: [],
                servingSize: 1,
                cookingTime: 1,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        )
        try context.save()

        let archive = Support.makeArchive(
            recipes: [
                Support.makeRecipe(
                    id: "recipe-1",
                    steps: ["One", "Two"]
                ),
                Support.makeRecipe(
                    id: "recipe-2",
                    steps: ["Three", "Four"]
                )
            ]
        )

        do {
            _ = try CookleDataArchiveService.restore(
                archive,
                context: context,
                limits: Support.makeLimits(
                    maximumAggregateNestedRecordCount: 3
                )
            )
            Issue.record("Expected nested record validation to fail.")
        } catch let CookleDataArchiveService.ArchiveError.resourceCountExceeded(
            category,
            actualCount,
            maximumCount
        ) {
            #expect(category == .nestedRecords)
            #expect(actualCount == 4)
            #expect(maximumCount == 3)
        } catch {
            Issue.record(error)
        }

        let recipes = try context.fetch(.recipes(.all))
        #expect(recipes.map(\.name) == ["Existing"])
    }
}
