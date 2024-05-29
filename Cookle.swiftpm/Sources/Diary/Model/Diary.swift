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
    private(set) var date: Date!
    @Relationship(deleteRule: .cascade, inverse: \DiaryObject.diary)
    private(set) var objects: [DiaryObject]!
    @Relationship(inverse: \Recipe.diaries)
    private(set) var recipes: [Recipe]!
    private(set) var note: String!
    private(set) var createdTimestamp: Date!
    private(set) var modifiedTimestamp: Date!

    private init() {
        self.date = .now
        self.objects = []
        self.recipes = []
        self.note = ""
        self.createdTimestamp = .now
        self.modifiedTimestamp = .now
    }

    static func create(context: ModelContext,
                       date: Date,
                       objects: [DiaryObject],
                       note: String) -> Diary {
        let diary = Diary()
        context.insert(diary)
        diary.date = date
        diary.objects = objects
        diary.recipes = objects.map { $0.recipe }
        diary.note = note
        return diary
    }

    func update(date: Date,
                objects: [DiaryObject],
                note: String) {
        self.date = date
        self.objects = objects
        self.recipes = objects.map { $0.recipe }
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
