//
//  TagStoreTests.swift
//  CookleTests
//
//  Created by Hiromu Nakano on 2024/04/12.
//

import XCTest
@testable import Cookle

final class TagStoreTests: XCTestCase {
    var tagStore = TagStore()

    let recipes: [Recipe] = (0..<10).map {
        .init(name: $0.description,
              ingredientList: [$0.description],
              instructionList: [$0.description],
              tagList: [$0.description])
    }

    override func setUp() {
        tagStore = .init()
    }

    func testModify() {
        tagStore.modify(recipes)
        XCTAssertEqual(tagStore.tagList.count, 42)
        XCTAssertEqual(tagStore.nameTagList.count, 10)
        XCTAssertEqual(tagStore.yearTagList.count, 1)
        XCTAssertEqual(tagStore.yearMonthTagList.count, 1)
        XCTAssertEqual(tagStore.ingredientTagList.count, 10)
        XCTAssertEqual(tagStore.instructionTagList.count, 10)
        XCTAssertEqual(tagStore.customTagList.count, 10)

        tagStore.modify(recipes)
        XCTAssertEqual(tagStore.tagList.count, 42)
        XCTAssertEqual(tagStore.nameTagList.count, 10)
        XCTAssertEqual(tagStore.yearTagList.count, 1)
        XCTAssertEqual(tagStore.yearMonthTagList.count, 1)
        XCTAssertEqual(tagStore.ingredientTagList.count, 10)
        XCTAssertEqual(tagStore.instructionTagList.count, 10)
        XCTAssertEqual(tagStore.customTagList.count, 10)

        tagStore.modify(recipes.dropLast())
        XCTAssertEqual(tagStore.tagList.count, 38)
        XCTAssertEqual(tagStore.nameTagList.count, 9)
        XCTAssertEqual(tagStore.yearTagList.count, 1)
        XCTAssertEqual(tagStore.yearMonthTagList.count, 1)
        XCTAssertEqual(tagStore.ingredientTagList.count, 9)
        XCTAssertEqual(tagStore.instructionTagList.count, 9)
        XCTAssertEqual(tagStore.customTagList.count, 9)
    }
}
