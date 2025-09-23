//
//  OpenCookleIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents

struct OpenCookleIntent: AppIntent {
    static var title: LocalizedStringResource {
        .init("Open Cookle")
    }

    static var openAppWhenRun: Bool {
        true
    }

    @MainActor
    func perform() throws -> some IntentResult {
        .result()
    }
}
