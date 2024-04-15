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
    let date: Date
    let breakfasts: [Recipe]
    let lunches: [Recipe]
    let dinners: [Recipe]

    init(date: Date, breakfasts: [Recipe], lunches: [Recipe], dinners: [Recipe]) {
        self.date = date
        self.breakfasts = breakfasts
        self.lunches = lunches
        self.dinners = dinners
    }
}
