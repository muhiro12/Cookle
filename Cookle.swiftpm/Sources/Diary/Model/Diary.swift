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
    private(set) var breakfasts: [Recipe]!
    private(set) var lunches: [Recipe]!
    private(set) var dinners: [Recipe]!

    private init() {
        self.date = .now
        self.breakfasts = []
        self.lunches = []
        self.dinners = []
    }

    static func create(context: ModelContext, date: Date, breakfasts: [Recipe], lunches: [Recipe], dinners: [Recipe]) -> Diary {
        let diary = Diary()
        context.insert(diary)
        diary.date = date
        diary.breakfasts = breakfasts
        diary.lunches = lunches
        diary.dinners = dinners
        return diary
    }
    
    func update(date: Date, breakfasts: [Recipe], lunches: [Recipe], dinners: [Recipe]) {
        self.date = date
        self.breakfasts = breakfasts
        self.lunches = lunches
        self.dinners = dinners
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
