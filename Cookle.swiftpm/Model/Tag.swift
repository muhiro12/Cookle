//
//  Tag.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftData

protocol Tag: PersistentModel {
    var value: String { get }
    var recipes: [Recipe] { get }
    static func create(context: ModelContext, value: String) -> Self
    func update(value: String)
}

extension Tag {
    static var descriptor: FetchDescriptor<Self> {
        .init(
            sortBy: [
                .init(\.value)
            ]
        )
    }
}
