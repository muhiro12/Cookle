//
//  Diary.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

@Model
public nonisolated final class Diary {
    public private(set) var date = Date.now
    @Relationship(deleteRule: .cascade)
    public private(set) var objects = [DiaryObject]?.some(.empty)
    @Relationship
    public private(set) var recipes = [Recipe]?.some(.empty)
    public private(set) var note = String.empty

    public private(set) var createdTimestamp = Date.now
    public private(set) var modifiedTimestamp = Date.now

    private init() {}

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
