@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("CookleRouteExecutor linked resources")
struct CookleRouteExecutorLinkedResourceTests {
    let context: ModelContext = makeTestContext()

    @Test("Resolves photo detail route to photo detail")
    func executeResolvesPhotoDetailRoute() throws {
        let photo = Photo.create(
            context: context,
            photoData: .init(
                data: Data("photo".utf8),
                source: .photosPicker
            )
        )
        let photoID = PersistentModelStableIdentifierCodec.stableIdentifier(
            for: photo
        )

        let outcome = try CookleRouteExecutor.execute(
            route: .photoDetail(photoID),
            context: context
        )

        switch outcome {
        case .photo(let resolvedPhoto):
            let resolvedPhoto = try #require(resolvedPhoto)
            #expect(
                resolvedPhoto.persistentModelID ==
                    photo.persistentModelID
            )
        case .home,
             .diary,
             .recipe,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense,
             .tagCategory,
             .tagIngredient:
            Issue.record("Expected .photo outcome for photo detail route.")
        }
    }

    @Test("Falls back to photo list for invalid photo detail route")
    func executeFallsBackToPhotoListForInvalidPhotoRoute() throws {
        let outcome = try CookleRouteExecutor.execute(
            route: .photoDetail("invalid"),
            context: context
        )

        switch outcome {
        case .photo(let resolvedPhoto):
            #expect(resolvedPhoto == nil)
        case .home,
             .diary,
             .recipe,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense,
             .tagCategory,
             .tagIngredient:
            Issue.record("Expected .photo fallback outcome for invalid photo route.")
        }
    }

    @Test("Resolves category tag detail route to category detail")
    func executeResolvesCategoryTagDetailRoute() throws {
        let category = Category.create(
            context: context,
            value: "Breakfast"
        )
        let categoryID = PersistentModelStableIdentifierCodec.stableIdentifier(
            for: category
        )

        let outcome = try CookleRouteExecutor.execute(
            route: .tagDetail(
                kind: .category,
                id: categoryID
            ),
            context: context
        )

        switch outcome {
        case .tagCategory(let resolvedCategory):
            let resolvedCategory = try #require(resolvedCategory)
            #expect(
                resolvedCategory.persistentModelID ==
                    category.persistentModelID
            )
        case .home,
             .diary,
             .photo,
             .recipe,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense,
             .tagIngredient:
            Issue.record("Expected .tagCategory outcome for category detail route.")
        }
    }

    @Test("Resolves ingredient tag detail route to ingredient detail")
    func executeResolvesIngredientTagDetailRoute() throws {
        let ingredient = Ingredient.create(
            context: context,
            value: "Egg"
        )
        let ingredientID = PersistentModelStableIdentifierCodec.stableIdentifier(
            for: ingredient
        )

        let outcome = try CookleRouteExecutor.execute(
            route: .tagDetail(
                kind: .ingredient,
                id: ingredientID
            ),
            context: context
        )

        switch outcome {
        case .tagIngredient(let resolvedIngredient):
            let resolvedIngredient = try #require(resolvedIngredient)
            #expect(
                resolvedIngredient.persistentModelID ==
                    ingredient.persistentModelID
            )
        case .home,
             .diary,
             .photo,
             .recipe,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense,
             .tagCategory:
            Issue.record("Expected .tagIngredient outcome for ingredient detail route.")
        }
    }

    @Test("Falls back to category tag list for invalid category tag route")
    func executeFallsBackToCategoryTagListForInvalidCategoryTagRoute() throws {
        let outcome = try CookleRouteExecutor.execute(
            route: .tagDetail(
                kind: .category,
                id: "invalid"
            ),
            context: context
        )

        switch outcome {
        case .tagCategory(let resolvedCategory):
            #expect(resolvedCategory == nil)
        case .home,
             .diary,
             .photo,
             .recipe,
             .search,
             .settings,
             .settingsSubscription,
             .settingsLicense,
             .tagIngredient:
            Issue.record("Expected .tagCategory fallback outcome for invalid tag route.")
        }
    }
}
