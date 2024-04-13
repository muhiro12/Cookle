//
//  Recipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    private(set) var name: String
    private(set) var ingredientList: [String]
    private(set) var instructionList: [String]
    private(set) var categoryList: [String]
    private(set) var updateDate: Date
    private(set) var creationDate: Date
    private(set) var yearMonth: String
    private(set) var yearMonthDay: String

    init(name: String, ingredientList: [String], instructionList: [String], categoryList: [String]) {
        self.name = name
        self.ingredientList = ingredientList
        self.instructionList = instructionList
        self.categoryList = categoryList

        self.updateDate = .now
        self.creationDate = .now
        self.yearMonth = ""
        self.yearMonthDay = ""

        self.setUpdateDate(updateDate)
    }

    func set(name: String, ingredientList: [String], instructionList: [String], categoryList: [String]) {
        self.name = name
        self.ingredientList = ingredientList
        self.instructionList = instructionList
        self.categoryList = categoryList

        self.setUpdateDate(.now)
    }

    func setUpdateDate(_ date: Date) {
        updateDate = date
        yearMonth = date.formatted(.iso8601.year().month())
        yearMonthDay = date.formatted(.iso8601.year().month().day())
    }
}
