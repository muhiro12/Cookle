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
    private(set) var source = PhotoSource?.some(.defaultValue)

    @Relationship(deleteRule: .cascade, inverse: \PhotoObject.photo)
    private(set) var objects = [PhotoObject]?.some(.empty)
    @Relationship(inverse: \Recipe.photos)
    private(set) var recipes = [Recipe]?.some(.empty)

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    static func create(context: ModelContext, photo: PhotoData) -> Photo {
        let photo = (try? context.fetchFirst(.photos(.dataIs(photo.data)))) ?? .init()
        context.insert(photo)
        photo.data = photo.data
        photo.source = photo.source
        return photo
    }
}

extension Photo {
    var title: String {
        recipes.orEmpty.map(\.name).joined(separator: ", ")
    }

    var sourceValue: PhotoSource {
        source ?? .defaultValue
    }
}

extension Photo: Identifiable {}
