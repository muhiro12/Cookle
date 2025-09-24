//
//  Diary.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

/// Persistent diary entity representing meals for a single day.
@Model
public nonisolated final class Diary {
    /// Target calendar date for this diary.
    public private(set) var date = Date.now
    @Relationship(deleteRule: .cascade)
    /// Meal items (breakfast/lunch/dinner) with order information.
    public private(set) var objects = [DiaryObject]?.some(.empty)
    @Relationship
    /// Flattened recipes derived from `objects`.
    public private(set) var recipes = [Recipe]?.some(.empty)
    /// Free-form note for the day.
    public private(set) var note = String.empty

    /// Creation timestamp.
    public private(set) var createdTimestamp = Date.now
    /// Last modification timestamp.
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

    /// Creates and inserts a diary with given objects and note.
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

    /// Updates the diary content and bumps the modification timestamp.
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
