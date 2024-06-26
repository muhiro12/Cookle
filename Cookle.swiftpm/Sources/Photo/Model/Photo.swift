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
    @Relationship(inverse: \Recipe.photos)
    private(set) var recipes = [Recipe]?.some(.empty)

    private init() {}

    static func create(context: ModelContext, data: Data) -> Photo {
        let photo = Photo()
        context.insert(photo)
        photo.data = data
        return photo
    }
}

extension Photo {
    var title: String {
        recipes.orEmpty.map {
            $0.name
        }.joined(separator: ", ")
    }
}

extension Photo {
    static var descriptor: FetchDescriptor<Photo> {
        .init()
    }
}

