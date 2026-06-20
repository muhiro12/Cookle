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
    public private(set) var objects = [DiaryObject]?.some([])
    /// Flattened recipe relation maintained from `objects` for quick lookup.
    @Relationship public private(set) var recipes = [Recipe]?.some([])
    /// Free-form note attached to the day.
    public private(set) var note = ""

    /// Timestamp captured when the diary is first inserted.
    public private(set) var createdTimestamp = Date.now
    /// Timestamp refreshed whenever the diary date, rows, or note changes.
    public private(set) var modifiedTimestamp = Date.now

    private init() {
        // SwiftData-managed initializer.
    }

    /// Inserts a diary and snapshots the supplied meal rows and derived recipe links.
    public static func create(
        context: ModelContext,
        content: DiaryContent
    ) -> Diary {
        let diary = Diary()
        context.insert(diary)
        diary.apply(content)
        return diary
    }

    static func restore(
        context: ModelContext,
        content: DiaryContent,
        timestamps: PersistentTimestamps
    ) -> Diary {
        let diary = create(
            context: context,
            content: content
        )
        diary.createdTimestamp = timestamps.created
        diary.modifiedTimestamp = timestamps.modified
        return diary
    }

    /// Replaces the stored date, meal rows, and note, then refreshes `modifiedTimestamp`.
    public func update(content: DiaryContent) {
        apply(content)
        self.modifiedTimestamp = .now
    }
}

private extension Diary {
    func apply(_ content: DiaryContent) {
        self.date = content.date
        self.objects = content.objects
        self.recipes = content.objects.compactMap(\.recipe)
        self.note = content.note
    }
}
