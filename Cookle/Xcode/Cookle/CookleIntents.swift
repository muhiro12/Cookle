//
//  CookleIntents.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import AppIntents
import CooklePlaygrounds

struct OpenCookleIntent: AppIntent {
    static var title = LocalizedStringResource("Open Cookle")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await CookleIntents.performOpenCookle()
    }
}
