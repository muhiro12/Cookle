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
    private(set) var imageList: [Data]
    private(set) var ingredientList: [String]
    private(set) var instructionList: [String]
    private(set) var tagList: [String]
    private(set) var updateDate: Date
    private(set) var creationDate: Date
    private(set) var year: String
    private(set) var yearMonth: String

    init(name: String, imageList: [Data], ingredientList: [String], instructionList: [String], tagList: [String]) {
        self.name = name
        self.imageList = imageList
        self.ingredientList = ingredientList
        self.instructionList = instructionList
        self.tagList = tagList

        self.updateDate = .now
        self.creationDate = .now
        self.year = ""
        self.yearMonth = ""

        self.setUpdateDate(updateDate)
    }

    func set(name: String, imageList: [Data], ingredientList: [String], instructionList: [String], tagList: [String]) {
        self.name = name
        self.imageList = imageList
        self.ingredientList = ingredientList
        self.instructionList = instructionList
        self.tagList = tagList

        self.setUpdateDate(.now)
    }

    func setUpdateDate(_ date: Date) {
        updateDate = date

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        year = formatter.string(from: date)
        formatter.dateFormat = "yyyyMMdd"
        yearMonth = formatter.string(from: date)
    }
}
