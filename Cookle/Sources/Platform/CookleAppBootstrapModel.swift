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

    private(set) var appAssembly: CookleAppAssembly? {
        didSet {
            notificationAppDelegate?.notificationService = appAssembly?.services.notificationService
        }
    }
    private(set) var failureMessage: String?
    private(set) var hasLoadedAssembly = false
    let activeEditors = CookleActiveEditors()

    private let logging: CookleAppLogging
    private let liveStoreLoader = LiveStoreLoader()
    @ObservationIgnored private weak var notificationAppDelegate: CookleNotificationAppDelegate?
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    private var requestedICloudSetting = false
    private var shouldRestoreSettings = false

    init(
        logging: CookleAppLogging = .live()
    ) {
        self.logging = logging
    }

    /// Starts synchronously because an App Intent can launch without a scene.
    func start(notificationAppDelegate: CookleNotificationAppDelegate) {
        self.notificationAppDelegate = notificationAppDelegate
        registerAppIntentDependencies()
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
        // the sync preferences are read below to decide how to open the store.
        let preferenceLifecycleStartedAt = Date.timeIntervalSinceReferenceDate
        let lifecycleOutcome = CookleKnownStorageDescriptors.preferenceRegistry.runSynchronously()
        logPreferenceLifecycleOutcome(
            lifecycleOutcome,
            startedAt: preferenceLifecycleStartedAt,
            startupLogger: startupLogger
        )

        let isICloudOn = iCloudSettingToApply
        requestedICloudSetting = isICloudOn

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

    func reloadAssemblyIfNeeded() {
        guard requestedICloudSetting != iCloudSettingToApply else {
            return
        }

        reloadAssembly()
    }

    func reloadAssembly() {
        let isICloudOn = iCloudSettingToApply
        loadTask?.cancel()
        requestedICloudSetting = isICloudOn
        if let appAssembly {
            shouldRestoreSettings = appAssembly.navigationModel.isSettingsPresented
            CookleMutationWorkflow.retire(appAssembly.modelContainer)
        }
        appAssembly = nil
        failureMessage = nil
        // A scene may disappear during a store reopen. The app owns the request.
        loadTask = Task { [weak self] in
            await self?.loadAssembly(isICloudOn: isICloudOn)
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

    var iCloudSettingToApply: Bool {
        // An open editor can postpone enabling sync, but cannot extend a subscription.
        CooklePreferences.bool(for: \.isSubscribeOn)
            && CooklePreferences.bool(for: \.isICloudOn)
            && (requestedICloudSetting || !activeEditors.isEditing)
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

    func loadAssembly(isICloudOn: Bool) async {
        guard !Task.isCancelled else {
            return
        }

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

        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = isICloudOn
            ? .automatic
            : .none

        do {
            let modelContainer = try await loadModelContainer(
                cloudKitDatabase: cloudKitDatabase,
                startupLogger: startupLogger
            )
            try Task.checkCancellation()
            guard isICloudOn == iCloudSettingToApply else {
                reloadAssemblyIfNeeded()
                return
            }

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
    #if DEBUG
    /// Loads the isolated capture assembly and reports whether capture mode handled startup.
    func loadCaptureAssemblyIfNeeded(
        startupStartedAt: TimeInterval,
        startupLogger: MHLogger
    ) -> Bool {
        guard CookleCaptureConfiguration.isEnabled else {
            return false
        }
        requestedICloudSetting = iCloudSettingToApply
        finalizeStartup(
            assembly: CookleSampleDataContext.makeCaptureContext(),
            startupStartedAt: startupStartedAt,
            startupLogger: startupLogger
        )
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
        assembly.navigationModel.isSettingsPresented = shouldRestoreSettings
        shouldRestoreSettings = false
        appAssembly = assembly
        hasLoadedAssembly = true
        CookleShortcuts.updateAppShortcutParameters()
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

    func registerAppIntentDependencies() {
        let loggingForDependency = logging
        AppDependencyManager.shared.add { loggingForDependency }
        registerAssemblyDependency { assembly in
            assembly.modelContainer
        }
        registerAssemblyDependency { assembly in
            assembly.recipeActionService
        }
        registerAssemblyDependency { assembly in
            assembly.diaryActionService
        }
        registerAssemblyDependency { assembly in
            assembly.tagActionService
        }
        registerAssemblyDependency { assembly in
            assembly.services.routePipeline
        }
    }

    func registerAssemblyDependency<Value: Sendable>(
        _ value: @escaping @MainActor @Sendable (CookleAppAssembly) -> Value
    ) {
        // A registration that captures the container keeps its CloudKit stack
        // alive even while the scene no longer uses it.
        AppDependencyManager.shared.add { @MainActor [weak self] () async throws -> Value in
            guard let self, let appAssembly,
                  requestedICloudSetting == iCloudSettingToApply else {
                throw CookleMutationWorkflow.MutationError.storeUnavailable
            }
            return value(appAssembly)
        }
    }
}
