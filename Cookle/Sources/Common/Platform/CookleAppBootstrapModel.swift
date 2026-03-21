import AppIntents
import Foundation
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

    private let startupLogger = CookleApp.logger(category: "AppStartup")

    func loadAssembly(
        isICloudOn: Bool
    ) async {
        appAssembly = nil
        failureMessage = nil

        startupLogger.notice("app startup began")

        let startupStartedAt = Date.timeIntervalSinceReferenceDate
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = isICloudOn
            ? .automatic
            : .none

        do {
            let storePreparationStartedAt = Date.timeIntervalSinceReferenceDate
            let modelContainer = try await Task.detached(
                priority: .userInitiated
            ) {
                try CookleAppAssemblyFactory.prepareLiveModelContainer(
                    cloudKitDatabase: cloudKitDatabase
                )
            }.value
            startupLogger.notice(
                "store prep finished in \(Self.durationMilliseconds(since: storePreparationStartedAt)) ms"
            )

            try Task.checkCancellation()

            let assembly = CookleAppAssemblyFactory.makeLiveAssembly(
                modelContainer: modelContainer
            )
            startupLogger.notice(
                "startup dependencies ready in \(Self.durationMilliseconds(since: startupStartedAt)) ms"
            )

            registerAppIntentDependencies(
                assembly: assembly
            )
            CookleShortcuts.updateAppShortcutParameters()

            appAssembly = assembly
            startupLogger.notice(
                "startup wiring finished in \(Self.durationMilliseconds(since: startupStartedAt)) ms"
            )
        } catch is CancellationError {
            return
        } catch {
            failureMessage = error.localizedDescription
            assertionFailure(error.localizedDescription)
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

    func registerAppIntentDependencies(
        assembly: CookleAppAssembly
    ) {
        let modelContainerForDependency = assembly.modelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }
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
