//
//  Photo.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import Foundation
import SwiftData

@Model
public nonisolated final class Photo {
    public private(set) var data = Data.empty
    public private(set) var sourceID = PhotoSource.defaultValue.rawValue

    @Relationship(deleteRule: .cascade, inverse: \PhotoObject.photo)
    public private(set) var objects = [PhotoObject]?.some(.empty)
    @Relationship(inverse: \Recipe.photos)
    public private(set) var recipes = [Recipe]?.some(.empty)

    public private(set) var createdTimestamp = Date.now
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    public static func create(context: ModelContext, photoData: PhotoData) -> Photo {
        let photo = (try? context.fetchFirst(.photos(.dataIs(photoData.data)))) ?? .init()
        context.insert(photo)
        photo.data = photoData.data
        photo.sourceID = photoData.source.rawValue
        return photo
    }
}

public extension Photo {
    public var title: String {
        recipes.orEmpty.map(\.name).joined(separator: ", ")
    }

    public var source: PhotoSource {
        .init(rawValue: sourceID) ?? .defaultValue
    }
}

public extension Photo: Identifiable {}
