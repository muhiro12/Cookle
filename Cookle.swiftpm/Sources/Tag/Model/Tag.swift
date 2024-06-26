//
//  Tag.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftData
import SwiftUI

protocol Tag: PersistentModel {
    var value: String { get }
    var recipes: [Recipe]? { get }
    var createdTimestamp: Date { get }
    var modifiedTimestamp: Date { get }

    static var title: LocalizedStringKey { get }
    static var descriptor: FetchDescriptor<Self> { get }

    static func create(context: ModelContext, value: String) -> Self
    func update(value: String)
}
