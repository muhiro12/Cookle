//
//  CollectionExtension.swift
//
//
//  Created by Hiromu Nakano on 2024/06/25.
//

extension Collection where Self: RangeReplaceableCollection {
    static var empty: Self {
        .init()
    }
}
