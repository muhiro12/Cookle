//
//  Diary.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import Foundation
import SwiftData

@Model
final class Diary: Identifiable {
    private(set) var date: Date!
    private(set) var objects: [DiaryObject]!
    @Relationship(inverse: \Recipe.diaries)
    private(set) var recipes: [Recipe]!

    private init() {
        self.date = .now
        self.objects = []
        self.recipes = []
    }

    static func create(context: ModelContext, date: Date, objects: [DiaryObject]) -> Diary {
        let diary = Diary()
        context.insert(diary)
        diary.date = date
        diary.objects = objects
        return diary
    }

    func update(date: Date, objects: [DiaryObject]) {
        self.date = date
        self.objects = objects
    }

    func delete() {
        modelContext?.delete(self)
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
