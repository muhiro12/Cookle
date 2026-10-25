@testable import CookleLibrary
import Foundation

/// Hand-authored format 1/schema 1.0.0 contract input, not a released-writer capture.
/// Keep its bytes independent of current model initializers and the current encoder
/// so a simultaneous writer/reader change cannot silently redefine V1.
enum CookleDataArchiveV1Fixture {
    static let schemaVersion = "1.0.0"

    static var package: CookleDataArchivePackage {
        .init(
            manifestData: Data(manifest.utf8),
            photoFiles: [
                .init(filename: "photo-000001.data", data: Data("V1 fixture".utf8))
            ]
        )
    }

    private static let manifest = #"""
        {
        "format": "com.muhiro12.Cookle.data",
        "formatVersion": 1,
        "schemaVersion": "1.0.0",
        "contents": { "scope": "all" },
        "exportedAt": "2023-11-14T22:13:20Z",
        "ingredients": [{
        "id": "ingredient-1",
        "value": "Eggs",
        "createdTimestamp": "2023-11-14T22:13:20Z",
        "modifiedTimestamp": "2023-11-14T22:13:20Z"
        }],
        "categories": [{
        "id": "category-1",
        "value": "Breakfast",
        "createdTimestamp": "2023-11-14T22:13:20Z",
        "modifiedTimestamp": "2023-11-14T22:13:20Z"
        }],
        "photos": [{
        "id": "photo-1",
        "filename": "photo-000001.data",
        "byteCount": 10,
        "sha256": "09ca2d00d318deff44ce639ecf3e3c6d85297d716a180e62dd502bd004e23344",
        "sourceID": "zW8rLxK4",
        "createdTimestamp": "2023-11-14T22:13:20Z",
        "modifiedTimestamp": "2023-11-14T22:13:20Z"
        }],
        "recipes": [{
        "id": "recipe-1",
        "name": "Pancakes",
        "servingSize": 2,
        "cookingTime": 15,
        "steps": ["Mix", "Cook"],
        "note": "Weekend\n週末",
        "categoryIDs": ["category-1"],
        "ingredients": [{
        "ingredientID": "ingredient-1",
        "amount": "2",
        "order": 0,
        "createdTimestamp": "2023-11-14T22:13:20Z",
        "modifiedTimestamp": "2023-11-14T22:13:20Z"
        }],
        "photos": [{
        "photoID": "photo-1",
        "order": 0,
        "createdTimestamp": "2023-11-14T22:13:20Z",
        "modifiedTimestamp": "2023-11-14T22:13:20Z"
        }],
        "createdTimestamp": "2023-11-14T22:13:20Z",
        "modifiedTimestamp": "2023-11-14T22:13:20Z"
        }],
        "diaries": [{
        "id": "diary-1",
        "date": "2023-11-14T22:13:20Z",
        "note": "Made together",
        "objects": [{
        "recipeID": "recipe-1",
        "type": { "breakfast": {} },
        "order": 0,
        "createdTimestamp": "2023-11-14T22:13:20Z",
        "modifiedTimestamp": "2023-11-14T22:13:20Z"
        }],
        "createdTimestamp": "2023-11-14T22:13:20Z",
        "modifiedTimestamp": "2023-11-14T22:13:20Z"
        }]
        }
    """#
}
