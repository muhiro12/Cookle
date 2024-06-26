//
//  Diary.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

@Model
final class Diary {
    private(set) var date = Date.now
    @Relationship(deleteRule: .cascade)
    private(set) var objects = [DiaryObject]?.some(.empty)
    @Relationship
    private(set) var recipes = [Recipe]?.some(.empty)
    private(set) var note = String.empty

    private(set) var createdTimestamp = Date.now
    private(set) var modifiedTimestamp = Date.now

    private init() {}

    static func create(context: ModelContext,
                       date: Date,
                       objects: [DiaryObject],
                       note: String) -> Diary {
        let diary = Diary()
        context.insert(diary)
        diary.date = date
        diary.objects = objects
        diary.recipes = objects.compactMap { $0.recipe }
        diary.note = note
        return diary
    }

    func update(date: Date,
                objects: [DiaryObject],
                note: String) {
        self.date = date
        self.objects = objects
        self.recipes = objects.compactMap { $0.recipe }
        self.note = note
        self.modifiedTimestamp = .now
    }
}

extension Diary {
    static var descriptor: FetchDescriptor<Diary> {
        .init(
            sortBy: [
                .init(\.date, order: .reverse)
            ]
        )
    }
}
