//
//  CookleIntents.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents

public enum CookleIntents {}

public extension CookleIntents {
    static func performOpenCookle() async throws -> some IntentResult {
        .result()
    }
}
