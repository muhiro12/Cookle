//
//  OpenCookleIntentTests.swift
//  Cookle
//
//  Created by Codex on 2025/07/12.
//

@testable import Cookle
import Testing

struct OpenCookleIntentTests {
    @Test func perform() throws {
        try OpenCookleIntent.perform(())
    }
}
