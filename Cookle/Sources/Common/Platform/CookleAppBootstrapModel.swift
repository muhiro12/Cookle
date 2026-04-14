import AppIntents
import Foundation
import MHPlatform
import SwiftData
import SwiftUI

@MainActor
@Observable
final class CookleAppBootstrapModel {
    private enum StartupConstants {
        static let millisecondsPerSecond = TimeInterval(
            Int("1000") ?? .zero
        )
    }

    private(set) var appAssembly: CookleAppAssembly?
    private(set) var failureMessage: String?

    private let logging: CookleAppLogging

    init(
        logging: CookleAppLogging = .live()
    ) {
        self.logging = logging
    }

    func loadAssembly(
        isICloudOn: Bool
    ) async {
        appAssembly = nil
        failureMessage = nil

        let startupLogger = makeLogger(
            category: "AppStartup"
        )
        startupLogger.notice("app startup began")

        let startupStartedAt = Date.timeIntervalSinceReferenceDate
        let preferenceLifecycleStartedAt = Date.timeIntervalSinceReferenceDate
        let lifecycleOutcome = await CooklePreferenceLifecycle.run()
        logPreferenceLifecycleOutcome(
            lifecycleOutcome,
            startedAt: preferenceLifecycleStartedAt,
            startupLogger: startupLogger
        )

        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = isICloudOn
            ? .automatic
            : .none

        do {
            let modelContainer = try await loadModelContainer(
                cloudKitDatabase: cloudKitDatabase,
                startupLogger: startupLogger
            )
            try Task.checkCancellation()
            let assembly = makeAssembly(
                modelContainer: modelContainer,
                startupStartedAt: startupStartedAt,
                startupLogger: startupLogger
            )
            finalizeStartup(
                assembly: assembly,
                startupStartedAt: startupStartedAt,
                startupLogger: startupLogger
            )
        } catch is CancellationError {
            return
        } catch {
            handleStartupFailure(
                error,
                startupLogger: startupLogger
            )
        }
    }
}

private extension CookleAppBootstrapModel {
    static func durationMilliseconds(
        since startedAt: TimeInterval
    ) -> Int {
        Int(
            (
                Date.timeIntervalSinceReferenceDate
                    - startedAt
            ) * StartupConstants.millisecondsPerSecond
        )
    }

    func loadModelContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        startupLogger: MHLogger
    ) async throws -> ModelContainer {
        let storePreparationStartedAt = Date.timeIntervalSinceReferenceDate
        let storeMigrationLogger = makeLogger(
            category: "StoreMigration"
        )
        let modelContainer = try await Task.detached(
            priority: .userInitiated
        ) {
            try CookleAppAssemblyFactory.prepareLiveModelContainer(
                cloudKitDatabase: cloudKitDatabase,
                logger: storeMigrationLogger
            )
        }.value
        startupLogger.notice(
            "store prep finished in \(Self.durationMilliseconds(since: storePreparationStartedAt)) ms"
        )
        return modelContainer
    }

    func logPreferenceLifecycleOutcome(
        _ lifecycleOutcome: MHPreferenceLifecycleOutcome,
        startedAt: TimeInterval,
        startupLogger: MHLogger
    ) {
        let removedKeyCount = lifecycleOutcome.cleanupReports
            .reduce(into: .zero) { count, report in
                count += report.report.removedStorageKeys.count
            }
        var metadata: [String: String] = [
            "migration_outcome": String(
                describing: lifecycleOutcome.migrationOutcome
            ),
            "removed_key_count": removedKeyCount.description,
            "cleanup_report_count": lifecycleOutcome.cleanupReports.count.description,
            "cleanup_domains": lifecycleOutcome.cleanupReports
                .map(\.domainName)
                .joined(separator: "|"),
            "cleanup_removed_key_counts": lifecycleOutcome.cleanupReports
                .map { report in
                    "\(report.domainName)=\(report.report.removedStorageKeys.count)"
                }
                .joined(separator: "|")
        ]

        let removedKeys = lifecycleOutcome.cleanupReports
            .flatMap { report in
                report.report.removedStorageKeys.map { storageKey in
                    "\(report.domainName):\(storageKey)"
                }
            }
            .sorted()
        if removedKeys.isEmpty == false {
            metadata["removed_keys"] = removedKeys.joined(separator: "|")
        }

        let message = "preference lifecycle finished in \(Self.durationMilliseconds(since: startedAt)) ms"
        if removedKeyCount > .zero {
            startupLogger.warning(
                message,
                metadata: metadata
            )
            return
        }

        startupLogger.notice(
            message,
            metadata: metadata
        )
    }

    func makeAssembly(
        modelContainer: ModelContainer,
        startupStartedAt: TimeInterval,
        startupLogger: MHLogger
    ) -> CookleAppAssembly {
        let assembly = CookleAppAssemblyFactory.makeLiveAssembly(
            modelContainer: modelContainer,
            logging: logging
        )
        startupLogger.notice(
            "startup dependencies ready in \(Self.durationMilliseconds(since: startupStartedAt)) ms"
        )
        return assembly
    }

    func finalizeStartup(
        assembly: CookleAppAssembly,
        startupStartedAt: TimeInterval,
        startupLogger: MHLogger
    ) {
        registerAppIntentDependencies(
            assembly: assembly
        )
        CookleShortcuts.updateAppShortcutParameters()

        appAssembly = assembly
        startupLogger.notice(
            "startup wiring finished in \(Self.durationMilliseconds(since: startupStartedAt)) ms"
        )
    }

    func handleStartupFailure(
        _ error: Error,
        startupLogger: MHLogger
    ) {
        failureMessage = error.localizedDescription
        startupLogger.error(
            "app startup failed",
            metadata: [
                "error_type": String(describing: type(of: error)),
                "error": error.localizedDescription
            ]
        )
        assertionFailure(error.localizedDescription)
    }

    func makeLogger(
        category: String
    ) -> MHLogger {
        logging.logger(
            category: category,
            source: #fileID
        )
    }

    func registerAppIntentDependencies(
        assembly: CookleAppAssembly
    ) {
        let modelContainerForDependency = assembly.modelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }
        let loggingForDependency = logging
        AppDependencyManager.shared.add { loggingForDependency }
        let recipeActionServiceForDependency = assembly.recipeActionService
        AppDependencyManager.shared.add { recipeActionServiceForDependency }
        let diaryActionServiceForDependency = assembly.diaryActionService
        AppDependencyManager.shared.add { diaryActionServiceForDependency }
        let tagActionServiceForDependency = assembly.tagActionService
        AppDependencyManager.shared.add { tagActionServiceForDependency }
        let settingsActionServiceForDependency = assembly.settingsActionService
        AppDependencyManager.shared.add { settingsActionServiceForDependency }
    }
}
