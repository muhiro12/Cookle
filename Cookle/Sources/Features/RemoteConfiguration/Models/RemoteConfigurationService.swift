//
//  RemoteConfigurationService.swift
//  Cookle
//
//  Created by Codex on 2025/06/17.
//

import CookleLibrary
import Foundation
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
    private let now: () -> Date

    private let remoteConfigurationURL = URL(
        string: "https://raw.githubusercontent.com/muhiro12/Cookle/main/.config.json"
    )
    private let appStoreLookupURL = URL(
        string: "https://itunes.apple.com/lookup?id=6483363226&country=jp"
    )

    init(
        session: URLSession = .shared,
        currentVersion: @escaping () -> String? = {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        },
        bundleIdentifier: @escaping () -> String? = {
            Bundle.main.bundleIdentifier
        },
        now: @escaping () -> Date = Date.init
    ) {
        self.session = session
        self.currentVersion = currentVersion
        self.bundleIdentifier = bundleIdentifier
        self.now = now
    }

    func load() async {
        isUpdateRequired = false

        guard let expectedBundleIdentifier = bundleIdentifier(),
              expectedBundleIdentifier.contains("playgrounds") == false,
              let remoteConfigurationURL,
              let appStoreLookupURL else {
            return
        }

        do {
            let remoteConfiguration = try await remoteConfiguration(
                from: remoteConfigurationURL
            )
            guard let forceUpdate = remoteConfiguration.forceUpdate,
                  let installedVersion = currentVersion().flatMap(AppVersion.init),
                  let minimumVersion = AppVersion(forceUpdate.minimumVersion),
                  let policy = RemoteUpdatePolicy(
                    minimumVersion: minimumVersion,
                    activatedAt: forceUpdate.activatedAt,
                    expiresAt: forceUpdate.expiresAt
                  ) else {
                return
            }

            let publicVersion = try await appStorePublicVersion(
                from: appStoreLookupURL,
                expectedBundleIdentifier: expectedBundleIdentifier
            )
            isUpdateRequired = policy.isUpdateRequired(
                currentVersion: installedVersion,
                publicVersion: publicVersion,
                now: now()
            )
        } catch {
            isUpdateRequired = false
        }
    }

    private func remoteConfiguration(
        from url: URL
    ) async throws -> RemoteConfiguration {
        let data = try await responseData(from: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(RemoteConfiguration.self, from: data)
    }

    private func appStorePublicVersion(
        from url: URL,
        expectedBundleIdentifier: String
    ) async throws -> AppVersion {
        let data = try await responseData(from: url)
        let lookupResponse = try JSONDecoder().decode(
            AppStoreLookupResponse.self,
            from: data
        )
        guard let result = lookupResponse.results.first(where: { result in
            result.trackID == Self.appStoreIdentifier
                && result.bundleID == expectedBundleIdentifier
        }),
        let publicVersion = AppVersion(result.version) else {
            throw URLError(.cannotParseResponse)
        }
        return publicVersion
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
