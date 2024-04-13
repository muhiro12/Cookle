//
//  InMemoryContextTests.swift
//  CookleTests
//
//  Created by Hiromu Nakano on 2024/04/12.
//

import XCTest
@testable import Cookle

final class InMemoryContextTests: XCTestCase {
    var inMemoryContext = InMemoryContext()

    let recipes: [Recipe] = (0..<10).map {
        .init(name: $0.description,
              ingredientList: [$0.description],
              instructionList: [$0.description],
              categoryList: [$0.description])
    }

    override func setUp() {
        inMemoryContext = .init()
    }

    func testModify() {
        inMemoryContext.modify(recipes)
        XCTAssertEqual(inMemoryContext.nameList.count, 10)
        XCTAssertEqual(inMemoryContext.yearMonthList.count, 1)
        XCTAssertEqual(inMemoryContext.yearMonthDayList.count, 1)
        XCTAssertEqual(inMemoryContext.ingredientList.count, 10)
        XCTAssertEqual(inMemoryContext.instructionList.count, 10)
        XCTAssertEqual(inMemoryContext.categoryList.count, 10)

        inMemoryContext.modify(recipes)
        XCTAssertEqual(inMemoryContext.nameList.count, 10)
        XCTAssertEqual(inMemoryContext.yearMonthList.count, 1)
        XCTAssertEqual(inMemoryContext.yearMonthDayList.count, 1)
        XCTAssertEqual(inMemoryContext.ingredientList.count, 10)
        XCTAssertEqual(inMemoryContext.instructionList.count, 10)
        XCTAssertEqual(inMemoryContext.categoryList.count, 10)

        inMemoryContext.modify(recipes.dropLast())
        XCTAssertEqual(inMemoryContext.nameList.count, 9)
        XCTAssertEqual(inMemoryContext.yearMonthList.count, 1)
        XCTAssertEqual(inMemoryContext.yearMonthDayList.count, 1)
        XCTAssertEqual(inMemoryContext.ingredientList.count, 9)
        XCTAssertEqual(inMemoryContext.instructionList.count, 9)
        XCTAssertEqual(inMemoryContext.categoryList.count, 9)
    }
}
