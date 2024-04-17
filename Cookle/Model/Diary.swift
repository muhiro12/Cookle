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
    private(set) var date: Date
    private(set) var breakfasts: [Recipe]
    private(set) var lunches: [Recipe]
    private(set) var dinners: [Recipe]
    private(set) var recipes: [Recipe]

    private init() {
        self.date = .now
        self.breakfasts = []
        self.lunches = []
        self.dinners = []
        self.recipes = []
    }

    static func create(date: Date, breakfasts: [Recipe], lunches: [Recipe], dinners: [Recipe]) -> Diary {
        let diary = Diary()
        diary.date = date
        diary.breakfasts = breakfasts
        diary.lunches = lunches
        diary.dinners = dinners
        diary.recipes = breakfasts + lunches + dinners
        return diary
    }
}
