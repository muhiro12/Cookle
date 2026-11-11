import AppIntents
import Foundation
import MHPlatform
import SwiftData
import SwiftUI

@MainActor
@Observable
final class CookleAppBootstrapModel {
    private enum StartupConstants {
        static let millisecondsPerSecond: TimeInterval = 1_000
    }

    private(set) var appAssembly: CookleAppAssembly?
    private(set) var failureMessage: String?
    private(set) var hasLoadedAssembly = false

    private let logging: CookleAppLogging
    private let liveStoreLoader = LiveStoreLoader()
    private var assembledICloudSetting = false

    init(
        logging: CookleAppLogging = .live()
    ) {
        self.logging = logging
    }

    /// Builds the assembly and registers App Intents dependencies without an
    /// `await`, for `CookleApp.init()`.
    ///
    /// An intent invoked while the app is not running launches the process
    /// without connecting a scene, so `body` never evaluates and the scene's
    /// `.task` never fires. Registering there left every dependent intent
    /// failing with "Failed to retrieve dependency of type ModelContainer".
    /// This mirrors the startup shape Incomes uses for the same reason.
    func loadAssemblySynchronously() {
        let startupLogger = makeLogger(
            category: "AppStartup"
        )
        startupLogger.notice("app startup began")

        let startupStartedAt = Date.timeIntervalSinceReferenceDate

        #if DEBUG
        if loadCaptureAssemblyIfNeeded(
            startupStartedAt: startupStartedAt,
            startupLogger: startupLogger
        ) {
            return
        }
        #endif

        // Runs on this thread without a task, so cleanup finishes before
        // `isICloudOn` is read below to decide how to open the store.
        let preferenceLifecycleStartedAt = Date.timeIntervalSinceReferenceDate
        let lifecycleOutcome = CookleKnownStorageDescriptors.preferenceRegistry.runSynchronously()
        logPreferenceLifecycleOutcome(
            lifecycleOutcome,
            startedAt: preferenceLifecycleStartedAt,
            startupLogger: startupLogger
        )

        // Read from the preference store rather than `@AppStorage`: the view
        // layer this would normally come from does not exist yet.
        let isICloudOn = CooklePreferences.bool(for: \.isICloudOn)

        do {
            let modelContainer = try CookleAppAssemblyFactory.prepareLiveModelContainer(
                cloudKitDatabase: isICloudOn ? .automatic : .none,
                logger: makeLogger(category: "StoreMigration")
            )
            installLiveAssembly(
                modelContainer: modelContainer,
                isICloudOn: isICloudOn,
                startupStartedAt: startupStartedAt,
                startupLogger: startupLogger
            )
        } catch {
            handleStartupFailure(
                error,
                startupLogger: startupLogger
            )
        }
    }

    /// Reports whether a scene-driven reload would repeat work `init()` already
    /// did for the same iCloud setting.
    func isAssembled(forICloudSetting isICloudOn: Bool) -> Bool {
        appAssembly != nil && assembledICloudSetting == isICloudOn
    }

    func loadAssembly(
        isICloudOn: Bool
    ) async {
        guard !Task.isCancelled else {
            return
        }

        appAssembly = nil
        failureMessage = nil

        let startupLogger = makeLogger(
            category: "AppStartup"
        )
        startupLogger.notice("app startup began")

        let startupStartedAt = Date.timeIntervalSinceReferenceDate

        #if DEBUG
        if loadCaptureAssemblyIfNeeded(
            startupStartedAt: startupStartedAt,
            startupLogger: startupLogger
        ) {
            return
        }
        #endif

        let preferenceLifecycleStartedAt = Date.timeIntervalSinceReferenceDate
        let lifecycleOutcome = await CookleKnownStorageDescriptors.preferenceRegistry.run()
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
            installLiveAssembly(
                modelContainer: modelContainer,
                isICloudOn: isICloudOn,
                startupStartedAt: startupStartedAt,
                startupLogger: startupLogger
            )
        } catch {
            guard !Task.isCancelled else {
                return
            }

            handleStartupFailure(
                error,
                startupLogger: startupLogger
            )
        }
    }
}

private extension CookleAppBootstrapModel {
    // Serialize opens of the same SQLite store even if a request is cancelled mid-open.
    actor LiveStoreLoader {
        func open(
            cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
            logger: MHLogger
        ) throws -> ModelContainer {
            try Task.checkCancellation()
            return try CookleAppAssemblyFactory.prepareLiveModelContainer(
                cloudKitDatabase: cloudKitDatabase,
                logger: logger
            )
        }
    }

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

    #if DEBUG
    /// Loads the isolated capture assembly and reports whether capture mode handled startup.
    func loadCaptureAssemblyIfNeeded(
        startupStartedAt: TimeInterval,
        startupLogger: MHLogger
    ) -> Bool {
        guard CookleCaptureConfiguration.isEnabled else {
            return false
        }
        finalizeStartup(
            assembly: CookleSampleDataContext.makeCaptureContext(),
            startupStartedAt: startupStartedAt,
            startupLogger: startupLogger
        )
        assembledICloudSetting = CooklePreferences.bool(for: \.isICloudOn)
        return true
    }
    #endif

    func loadModelContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase,
        startupLogger: MHLogger
    ) async throws -> ModelContainer {
        let storePreparationStartedAt = Date.timeIntervalSinceReferenceDate
        let storeMigrationLogger = makeLogger(
            category: "StoreMigration"
        )
        let modelContainer = try await liveStoreLoader.open(
            cloudKitDatabase: cloudKitDatabase,
            logger: storeMigrationLogger
        )
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

    func installLiveAssembly(
        modelContainer: ModelContainer,
        isICloudOn: Bool,
        startupStartedAt: TimeInterval,
        startupLogger: MHLogger
    ) {
        let assembly = makeAssembly(
            modelContainer: modelContainer,
            startupStartedAt: startupStartedAt,
            startupLogger: startupLogger
        )
        assembledICloudSetting = isICloudOn
        finalizeStartup(
            assembly: assembly,
            startupStartedAt: startupStartedAt,
            startupLogger: startupLogger
        )
        startupLogger.notice(
            "iCloud store configuration applied",
            metadata: ["icloud_enabled": isICloudOn.description]
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
        hasLoadedAssembly = true
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
        let routePipelineForDependency = assembly.services.routePipeline
        AppDependencyManager.shared.add { routePipelineForDependency }
    }
}
