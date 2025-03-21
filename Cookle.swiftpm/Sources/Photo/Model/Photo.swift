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

    @Relationship(deleteRule: .cascade, inverse: \PhotoObject.photo)
    private(set) var objects = [PhotoObject]?.some(.empty)
    @Relationship(inverse: \Recipe.photos)
    private(set) var recipes = [Recipe]?.some(.empty)

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    static func create(context: ModelContext, data: Data) -> Photo {
        let photo = (try? context.fetchFirst(.photos(.dataIs(data)))) ?? .init()
        context.insert(photo)
        photo.data = data
        return photo
    }
}

extension Photo {
    var title: String {
        recipes.orEmpty.map(\.name).joined(separator: ", ")
    }
}
