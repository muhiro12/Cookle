//
//  OptionalExtension.swift
//
//
//  Created by Hiromu Nakano on 2024/06/25.
//

extension Optional where Wrapped: RangeReplaceableCollection {
    var orEmpty: Wrapped {
        self ?? .init()
    }
}
