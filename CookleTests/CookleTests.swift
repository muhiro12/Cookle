//
//  CookleTests.swift
//  CookleTests
//
//  Created by Hiromu Nakano on 2025/06/20.
//

@testable import Cookle
import SwiftData

var testContext: ModelContext {
    let schema = Schema([Recipe.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return .init(
        try! .init(for: schema, configurations: [configuration])
    )
}
