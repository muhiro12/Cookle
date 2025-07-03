//
//  Photo.swift
//
//
//  Created by Hiromu Nakano on 2024/06/26.
//

import Foundation
import SwiftData

@Model
final class Photo {
    private(set) var data = Data.empty
    private(set) var sourceID = PhotoSource.defaultValue.rawValue

    @Relationship(deleteRule: .cascade, inverse: \PhotoObject.photo)
    private(set) var objects = [PhotoObject]?.some(.empty)
    @Relationship(inverse: \Recipe.photos)
    private(set) var recipes = [Recipe]?.some(.empty)

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    @MainActor
    static func create(context: ModelContext, photoData: PhotoData) -> Photo {
        let photo = (try? context.fetchFirst(.photos(.dataIs(photoData.data)))) ?? .init()
        context.insert(photo)
        photo.data = photoData.data
        photo.sourceID = photoData.source.rawValue
        return photo
    }
}

extension Photo {
    var title: String {
        recipes.orEmpty.map(\.name).joined(separator: ", ")
    }

    var source: PhotoSource {
        .init(rawValue: sourceID) ?? .defaultValue
    }
}

extension Photo: Identifiable {}
