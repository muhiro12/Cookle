//
//  InMemoryContext.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/09.
//

import Foundation

@Observable
final class InMemoryContext {

    var nameList: [some Tag] {
        nameSet.sorted()
    }

    var yearMonthList: [some Tag] {
        yearMonthSet.sorted { $0 > $1 }
    }

    var yearMonthDayList: [some Tag] {
        yearMonthDaySet.sorted { $0 > $1 }
    }

    var ingredientList: [some Tag] {
        ingredientSet.sorted()
    }

    var instructionList: [some Tag] {
        instructionSet.sorted()
    }

    var categoryList: [some Tag] {
        categorySet.sorted()
    }

    private var nameSet = Set<Name>()
    private var yearMonthSet = Set<YearMonth>()
    private var yearMonthDaySet = Set<YearMonthDay>()
    private var ingredientSet = Set<Ingredient>()
    private var instructionSet = Set<Instruction>()
    private var categorySet = Set<Category>()

    func tagList<T: Tag>() -> [T] {
        switch T.self {
        case is Name.Type:
            nameList as! [T]
        case is YearMonth.Type:
            yearMonthList as! [T]
        case is YearMonthDay.Type:
            yearMonthDayList as! [T]
        case is Ingredient.Type:
            ingredientList as! [T]
        case is Instruction.Type:
            instructionList as! [T]
        case is Category.Type:
            categoryList as! [T]
        default:
            []
        }
    }

    func modify(_ recipes: [Recipe]) {
        clear()
        recipes.forEach(insert)
    }

    func insert(with recipe: Recipe) {
        insert(Name(value: recipe.name))
        insert(YearMonth(value: recipe.yearMonth))
        insert(YearMonthDay(value: recipe.yearMonthDay))
        recipe.ingredientList.forEach {
            insert(Ingredient(value: $0))
        }
        recipe.instructionList.forEach {
            insert(Instruction(value: $0))
        }
        recipe.categoryList.forEach { tag in
            insert(Category(value: tag))
        }
    }

    private func insert(_ tag: some Tag) {
        switch tag {
        case let tag as Name:
            nameSet.insert(tag)
        case let tag as YearMonth:
            yearMonthSet.insert(tag)
        case let tag as YearMonthDay:
            yearMonthDaySet.insert(tag)
        case let tag as Ingredient:
            ingredientSet.insert(tag)
        case let tag as Instruction:
            instructionSet.insert(tag)
        case let tag as Category:
            categorySet.insert(tag)
        default:
            break
        }
    }

    private func clear() {
        nameSet.removeAll()
        yearMonthSet.removeAll()
        yearMonthDaySet.removeAll()
        ingredientSet.removeAll()
        instructionSet.removeAll()
        categorySet.removeAll()
    }
}
