//
//  ConfigurationService.swift
//  Cookle
//
//  Created by Codex on 2025/06/17.
//

import Foundation
import SwiftUI

@Observable
final class ConfigurationService {
    private(set) var configuration: Configuration?

    private let decoder = JSONDecoder()

    func load() async throws {
        guard let configurationURL = URL(
            string: "https://raw.githubusercontent.com/muhiro12/Cookle/main/.config.json"
        ) else {
            throw URLError(.badURL)
        }
        let data = try await URLSession.shared.data(from: configurationURL).0
        configuration = try decoder.decode(Configuration.self, from: data)
    }

    func isUpdateRequired() -> Bool {
        guard let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              let required = configuration?.requiredVersion,
              Bundle.main.bundleIdentifier?.contains("playgrounds") == false else {
            return false
        }
        return current.compare(required, options: .numeric) == .orderedAscending
    }
}
