//
//  Photo.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import Foundation
import SwiftData

/// Photo binary data and associations.
@Model
nonisolated public final class Photo {
    /// Raw image bytes.
    public private(set) var data = Data.empty
    /// Encoded source identifier (see `PhotoSource`).
    public private(set) var sourceID = PhotoSource.defaultValue.rawValue

    @Relationship(deleteRule: .cascade, inverse: \PhotoObject.photo)
    /// Photo objects linked to recipes.
    public private(set) var objects = [PhotoObject]?.some(.empty)
    @Relationship(inverse: \Recipe.photos)
    /// Recipes using this photo.
    public private(set) var recipes = [Recipe]?.some(.empty)

    /// Creation timestamp.
    public private(set) var createdTimestamp = Date.now
    /// Last modification timestamp.
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    /// Creates (or returns) a photo for the given data.
    public static func create(context: ModelContext, photoData: PhotoData) -> Photo {
        let photo = (try? context.fetchFirst(.photos(.dataIs(photoData.data)))) ?? .init()
        context.insert(photo)
        photo.data = photoData.data
        photo.sourceID = photoData.source.rawValue
        return photo
    }
}

public extension Photo {
    /// Comma-separated recipe names that reference this photo.
    var title: String {
        recipes.orEmpty.map(\.name).joined(separator: ", ")
    }

    /// Strongly typed photo source.
    var source: PhotoSource {
        .init(rawValue: sourceID) ?? .defaultValue
    }
}

extension Photo: Identifiable {}
