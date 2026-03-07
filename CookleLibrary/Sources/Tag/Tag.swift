//
//  Tag.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData
import SwiftUI

/// Shared contract for persisted tags that recipes use for filtering and labeling.
nonisolated public protocol Tag: PersistentModel {
    /// Localized section title used when presenting this tag type in the UI.
    static var title: LocalizedStringKey { get }

    /// Canonical text value users select, edit, and search against.
    var value: String { get }
    /// Recipes that currently reference this tag.
    var recipes: [Recipe]? { get } // swiftlint:disable:this discouraged_optional_collection
    /// Timestamp captured when the tag record is first inserted.
    var createdTimestamp: Date { get }
    /// Timestamp refreshed whenever the stored tag value changes.
    var modifiedTimestamp: Date { get }

    /// Returns an existing tag for `value`, or inserts a new record when none exists.
    static func create(context: ModelContext, value: String) -> Self
    /// Builds a fetch descriptor for this tag type using the caller's sort order.
    static func descriptor(_ predicate: TagPredicate<Self>, order: SortOrder) -> FetchDescriptor<Self>
    /// Builds a fetch descriptor for this tag type using the default sort order.
    static func descriptor(_ predicate: TagPredicate<Self>) -> FetchDescriptor<Self>

    /// Replaces the stored tag value and refreshes `modifiedTimestamp`.
    func update(value: String)
}
