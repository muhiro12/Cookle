//
//  OpenCookleIntent.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2025/06/16.
//

import AppIntents
import SwiftUtilities

struct OpenCookleIntent: AppIntent, IntentPerformer {
    typealias Input = Void
    typealias Output = Void

    static var title: LocalizedStringResource {
        .init("Open Cookle")
    }

    static var openAppWhenRun: Bool {
        true
    }

    static func perform(_: Input) throws -> Output {}

    @MainActor
    func perform() throws -> some IntentResult {
        try Self.perform(())
        return .result()
    }
}
