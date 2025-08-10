//
//  OpenCookleIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents

@MainActor
struct OpenCookleIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource {
        .init("Open Cookle")
    }

    nonisolated static var openAppWhenRun: Bool {
        true
    }

    func perform() throws -> some IntentResult {
        .result()
    }
}
