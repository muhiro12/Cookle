//
//  PhotoObject.swift
//
//
//  Created by Hiromu Nakano on 2024/06/27.
//

import Foundation
import SwiftData

@Model
nonisolated public final class PhotoObject: SubObject {
    @Relationship public private(set) var photo = Photo?.none
    public private(set) var order = Int.zero

    @Relationship(inverse: \Recipe.photoObjects)
    public private(set) var recipe = Recipe?.none

    public private(set) var createdTimestamp = Date.now
    public private(set) var modifiedTimestamp = Date.now

    private init(photo: Photo) {
        self.photo = photo
    }

    public static func create(context: ModelContext, photoData: PhotoData, order: Int) -> PhotoObject {
        let object = PhotoObject(
            photo: .create(context: context, photoData: photoData)
        )
        context.insert(object)
        object.order = order
        return object
    }

    static func restore(
        context: ModelContext,
        photo: Photo,
        order: Int,
        createdTimestamp: Date,
        modifiedTimestamp: Date
    ) -> PhotoObject {
        let object = PhotoObject(
            photo: photo
        )
        context.insert(object)
        object.order = order
        object.createdTimestamp = createdTimestamp
        object.modifiedTimestamp = modifiedTimestamp
        return object
    }
}
