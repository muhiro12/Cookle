//
//  PhotoObject.swift
//
//
//  Created by Hiromu Nakano on 2024/06/27.
//

import Foundation
import SwiftData

@Model
final class PhotoObject: SubObject {
    @Relationship
    private(set) var photo = Photo?.none
    private(set) var order = Int.zero

    @Relationship(inverse: \Recipe.photoObjects)
    private(set) var recipe = Recipe?.none

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init(photo: Photo) {
        self.photo = photo
    }

    static func create(context: ModelContext, photoData: PhotoData, order: Int) -> PhotoObject {
        let object = PhotoObject(
            photo: .create(context: context, photoData: photoData)
        )
        context.insert(object)
        object.order = order
        return object
    }
}
