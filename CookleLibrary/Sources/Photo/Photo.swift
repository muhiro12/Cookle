//
//  Photo.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import Foundation
import SwiftData

/// Persisted photo asset that can be shared across recipe photo rows.
@Model
nonisolated public final class Photo {
    /// Binary image data stored for the asset.
    public private(set) var data = Data()
    /// Persisted source identifier used to recover a typed `PhotoSource`.
    public private(set) var sourceID = PhotoSource.defaultValue.rawValue

    /// Recipe photo rows that reference this asset.
    @Relationship(deleteRule: .cascade, inverse: \PhotoObject.photo)
    public private(set) var objects = [PhotoObject]?.some([])
    /// Recipes that currently reference this asset.
    @Relationship(inverse: \Recipe.photos)
    public private(set) var recipes = [Recipe]?.some([])

    /// Timestamp captured when the asset is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp retained for recency-based queries on photo assets.
    public private(set) var modifiedTimestamp = Date.now

    private init() {
        // SwiftData-managed initializer.
    }

    /// Returns an existing asset for matching binary data, or inserts a new one and stores its source.
    public static func create(context: ModelContext, photoData: PhotoData) -> Photo {
        let photo = (try? context.fetchFirst(.photos(.dataIs(photoData.data)))) ?? .init()
        context.insert(photo)
        photo.data = photoData.data
        photo.sourceID = photoData.source.rawValue
        return photo
    }

    static func restore(
        context: ModelContext,
        data: Data,
        sourceID: String,
        createdTimestamp: Date,
        modifiedTimestamp: Date
    ) -> Photo {
        let photo = Photo()
        context.insert(photo)
        photo.data = data
        photo.sourceID = sourceID
        photo.createdTimestamp = createdTimestamp
        photo.modifiedTimestamp = modifiedTimestamp
        return photo
    }
}

public extension Photo {
    /// Comma-separated recipe names that currently reference this asset, or `nil` when unlinked.
    var linkedRecipeNames: String? {
        let recipeNames = (recipes ?? []).map(\.name).joined(separator: ", ")
        guard !recipeNames.isEmpty else {
            return nil
        }
        return recipeNames
    }

    /// Typed photo source derived from `sourceID`, with a safe default for unknown values.
    var source: PhotoSource {
        .init(rawValue: sourceID) ?? .defaultValue
    }
}

extension Photo: Identifiable {}
