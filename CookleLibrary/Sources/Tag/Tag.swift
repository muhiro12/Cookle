//
//  Tag.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData
import SwiftUI

/// Common contract for tag-like models (e.g. `Ingredient`, `Category`).
nonisolated public protocol Tag: PersistentModel {
    /// Display value of the tag.
    var value: String { get }
    /// Recipes associated with this tag.
    var recipes: [Recipe]? { get }
    /// Creation timestamp.
    var createdTimestamp: Date { get }
    /// Last modification timestamp.
    var modifiedTimestamp: Date { get }

    /// Creates (or returns) a tag with the given value.
    static func create(context: ModelContext, value: String) -> Self
    /// Updates the tag's value.
    func update(value: String)

    /// Localized title used in UI.
    static var title: LocalizedStringKey { get }

    /// Convenience descriptor using a predicate and explicit order.
    static func descriptor(_ predicate: TagPredicate<Self>, order: SortOrder) -> FetchDescriptor<Self>
    /// Convenience descriptor using a predicate with default order.
    static func descriptor(_ predicate: TagPredicate<Self>) -> FetchDescriptor<Self>
}
