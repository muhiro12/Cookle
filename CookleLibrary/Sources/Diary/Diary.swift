//
//  Diary.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

/// Persisted day-level meal log that groups recipes and notes for one calendar date.
@Model
nonisolated public final class Diary {
    /// Calendar date represented by this diary entry.
    public private(set) var date = Date.now
    /// Meal rows stored for the day, including section and display order.
    @Relationship(deleteRule: .cascade)
    public private(set) var objects = [DiaryObject]?.some(.empty)
    /// Flattened recipe relation maintained from `objects` for quick lookup.
    @Relationship public private(set) var recipes = [Recipe]?.some(.empty)
    /// Free-form note attached to the day.
    public private(set) var note = String.empty

    /// Timestamp captured when the diary is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp refreshed whenever the diary date, rows, or note changes.
    public private(set) var modifiedTimestamp = Date.now

    private init() {
        // SwiftData-managed initializer.
    }

    /// Inserts a diary and snapshots the supplied meal rows and derived recipe links.
    public static func create(context: ModelContext,
                              date: Date,
                              objects: [DiaryObject],
                              note: String) -> Diary {
        let diary = Diary()
        context.insert(diary)
        diary.date = date
        diary.objects = objects
        diary.recipes = objects.compactMap(\.recipe)
        diary.note = note
        return diary
    }

    /// Replaces the stored date, meal rows, and note, then refreshes `modifiedTimestamp`.
    public func update(date: Date,
                       objects: [DiaryObject],
                       note: String) {
        self.date = date
        self.objects = objects
        self.recipes = objects.compactMap(\.recipe)
        self.note = note
        self.modifiedTimestamp = .now
    }
}
