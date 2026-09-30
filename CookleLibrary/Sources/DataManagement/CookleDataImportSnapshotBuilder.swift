import CryptoKit
import Foundation
import SwiftData

/// Builds comparable snapshots of current and imported records.
///
/// Photo digests are computed at most once per photo so comparing candidates
/// never re-hashes or copies image bytes repeatedly.
@MainActor
final class CookleDataImportSnapshotBuilder {
    private let archive: CookleDataArchive
    private let archivePhotos: [String: CookleDataArchive.PhotoRecord]
    private let archiveIngredients: [String: String]
    private let archiveCategories: [String: String]
    private var archiveDigests = [String: Data]()
    private var currentDigests = [PersistentIdentifier: Data]()

    init(archive: CookleDataArchive) {
        self.archive = archive
        archivePhotos = Dictionary(
            uniqueKeysWithValues: archive.photos.map { photo in
                (photo.id, photo)
            }
        )
        archiveIngredients = Dictionary(
            uniqueKeysWithValues: archive.ingredients.map { ingredient in
                (ingredient.id, ingredient.value)
            }
        )
        archiveCategories = Dictionary(
            uniqueKeysWithValues: archive.categories.map { category in
                (category.id, category.value)
            }
        )
    }

    nonisolated static func digest(of data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }

    /// Normalizes a recipe name the way duplicate-looking tags are compared.
    nonisolated static func nameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { component in
                component.isEmpty == false
            }
            .joined(separator: " ")
            .folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive,
                    .widthInsensitive
                ],
                locale: .current
            )
    }

    nonisolated static func sortedNames(_ names: [String]) -> [String] {
        names.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
    }

    func archiveDigest(forPhotoID photoID: String) -> Data? {
        if let digest = archiveDigests[photoID] {
            return digest
        }
        guard let record = archivePhotos[photoID] else {
            return nil
        }

        let digest = Self.digest(of: record.data)
        archiveDigests[photoID] = digest
        return digest
    }

    func currentDigest(for photo: Photo) -> Data {
        if let digest = currentDigests[photo.persistentModelID] {
            return digest
        }

        let digest = Self.digest(of: photo.data)
        currentDigests[photo.persistentModelID] = digest
        return digest
    }

    /// Binds approval to all file content without encoding full image bytes again.
    func archiveIdentity(includingExportDate: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var hash = SHA256()
        hash.update(data: try encoder.encode(archive.scope.rawValue))
        if includingExportDate {
            hash.update(data: try encoder.encode(archive.exportedAt))
        }
        hash.update(data: try encoder.encode(archive.ingredients))
        hash.update(data: try encoder.encode(archive.categories))
        hash.update(data: try encoder.encode(archive.recipes))
        hash.update(data: try encoder.encode(archive.diaries))
        for photo in archive.photos {
            let compact = CookleDataArchive.PhotoRecord(
                id: photo.id,
                data: archiveDigest(forPhotoID: photo.id) ?? Data(),
                sourceID: photo.sourceID,
                createdTimestamp: photo.createdTimestamp,
                modifiedTimestamp: photo.modifiedTimestamp
            )
            hash.update(data: try encoder.encode(compact))
        }
        return Data(hash.finalize())
    }

    func snapshot(
        of record: CookleDataArchive.RecipeRecord
    ) -> CookleDataImportReview.RecipeSnapshot {
        .init(
            name: record.name,
            servingSize: record.servingSize,
            cookingTime: record.cookingTime,
            ingredients: record.ingredients
                .sorted { lhs, rhs in
                    lhs.order < rhs.order
                }
                .map { ingredient in
                    .init(
                        name: archiveIngredients[ingredient.ingredientID] ?? "",
                        amount: ingredient.amount
                    )
                },
            steps: record.steps,
            categories: Self.sortedNames(
                record.categoryIDs.compactMap { categoryID in
                    archiveCategories[categoryID]
                }
            ),
            note: record.note,
            photos: record.photos
                .sorted { lhs, rhs in
                    lhs.order < rhs.order
                }
                .compactMap { photo in
                    guard let photoRecord = archivePhotos[photo.photoID],
                          let digest = archiveDigest(forPhotoID: photo.photoID) else {
                        return nil
                    }
                    return .init(
                        data: photoRecord.data,
                        sourceID: photoRecord.sourceID,
                        digest: digest
                    )
                }
        )
    }

    func snapshot(
        of recipe: Recipe
    ) -> CookleDataImportReview.RecipeSnapshot {
        .init(
            name: recipe.name,
            servingSize: recipe.servingSize,
            cookingTime: recipe.cookingTime,
            ingredients: (recipe.ingredientObjects ?? [])
                .sorted()
                .map { object in
                    .init(
                        name: object.ingredient?.value ?? "",
                        amount: object.amount
                    )
                },
            steps: recipe.steps,
            categories: Self.sortedNames(
                (recipe.categories ?? []).map(\.value)
            ),
            note: recipe.note,
            photos: recipe.orderedPhotoObjects.compactMap { object in
                guard let photo = object.photo else {
                    return nil
                }
                return .init(
                    data: photo.data,
                    sourceID: photo.sourceID,
                    digest: currentDigest(for: photo)
                )
            }
        )
    }
}
