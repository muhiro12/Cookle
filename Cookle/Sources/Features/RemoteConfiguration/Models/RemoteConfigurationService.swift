//
//  RemoteConfigurationService.swift
//  Cookle
//
//  Created by Codex on 2025/06/17.
//

import CookleLibrary
import Foundation
import MHPlatform
import SwiftUI

@MainActor
@Observable
final class RemoteConfigurationService {
    private enum HTTPStatus {
        static let successLowerBound = 200
        static let successUpperBound = 300
    }

    private static let appStoreIdentifier = 6_483_363_226

    private(set) var isUpdateRequired = false

    private let session: URLSession
    private let currentVersion: () -> String?
    private let bundleIdentifier: () -> String?
    private let now: @Sendable () -> Date
    private var loadIdentifier: UUID?

    private let remoteConfigurationURL = URL(
        string: "https://raw.githubusercontent.com/muhiro12/Cookle/main/.config.json"
    )

    init(
        session: URLSession = .shared,
        currentVersion: @escaping () -> String? = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        },
        bundleIdentifier: @escaping () -> String? = {
            Bundle.main.bundleIdentifier
        },
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.session = session
        self.currentVersion = currentVersion
        self.bundleIdentifier = bundleIdentifier
        self.now = now
    }

    func load() async {
        guard Task.isCancelled == false else {
            return
        }
        let identifier = UUID()
        loadIdentifier = identifier
        isUpdateRequired = false

        guard let expectedBundleIdentifier = bundleIdentifier(),
              expectedBundleIdentifier.contains("playgrounds") == false,
              let remoteConfigurationURL else {
            return
        }

        do {
            let remoteConfiguration = try await remoteConfiguration(
                from: remoteConfigurationURL
            )
            guard let forceUpdate = remoteConfiguration.forceUpdate,
                  let minimumVersion = AppVersion(forceUpdate.minimumVersion),
                  let policy = RemoteUpdatePolicy(
                    minimumVersion: minimumVersion,
                    activatedAt: forceUpdate.activatedAt,
                    expiresAt: forceUpdate.expiresAt
                  ) else {
                return
            }

            let decision = try await updateDecision(
                for: policy,
                expectedBundleIdentifier: expectedBundleIdentifier
            )
            try Task.checkCancellation()
            guard loadIdentifier == identifier else {
                return
            }
            isUpdateRequired = decision == .updateRequired
        } catch {
            guard loadIdentifier == identifier, Task.isCancelled == false else {
                return
            }
            isUpdateRequired = false
        }
    }

    private func updateDecision(
        for policy: RemoteUpdatePolicy,
        expectedBundleIdentifier: String
    ) async throws -> MHRemoteUpdateDecision {
        let installedVersion = currentVersion()
        let identifier = Self.appStoreIdentifier
        let lookup = MHAppStoreVersionLookup(session: session)
        let publicVersion: @Sendable () async throws -> MHAppVersion? = {
            try await lookup.version(
                appID: identifier,
                bundleIdentifier: expectedBundleIdentifier,
                country: "jp"
            )
        }
        let evaluator = MHRemoteUpdateEvaluator(
            currentVersion: {
                installedVersion
            },
            now: now,
            publicVersion: publicVersion
        )
        return try await evaluator.evaluate(policy.updatePolicy)
    }

    private func remoteConfiguration(
        from url: URL
    ) async throws -> RemoteConfiguration {
        let data = try await responseData(from: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(RemoteConfiguration.self, from: data)
    }

    private func responseData(from url: URL) async throws -> Data {
        let (data, urlResponse) = try await session.data(from: url)
        guard let httpResponse = urlResponse as? HTTPURLResponse,
              (HTTPStatus.successLowerBound ..< HTTPStatus.successUpperBound)
                .contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
