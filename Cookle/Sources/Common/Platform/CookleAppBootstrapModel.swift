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

    private(set) var platformEnvironment: CooklePlatformEnvironment?
    private(set) var failureMessage: String?

    private let startupLogger = CookleApp.logger(category: "AppStartup")

    func loadEnvironment(
        isICloudOn: Bool
    ) async {
        platformEnvironment = nil
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
                try CooklePlatformEnvironmentFactory.prepareLiveModelContainer(
                    cloudKitDatabase: cloudKitDatabase
                )
            }.value
            startupLogger.notice(
                "store prep finished in \(Self.durationMilliseconds(since: storePreparationStartedAt)) ms"
            )

            try Task.checkCancellation()

            let environment = CooklePlatformEnvironmentFactory.makeLiveEnvironment(
                modelContainer: modelContainer
            )
            startupLogger.notice(
                "startup dependencies ready in \(Self.durationMilliseconds(since: startupStartedAt)) ms"
            )

            registerAppIntentDependencies(
                environment: environment
            )
            CookleShortcuts.updateAppShortcutParameters()

            platformEnvironment = environment
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
        environment: CooklePlatformEnvironment
    ) {
        let modelContainerForDependency = environment.modelContainer
        AppDependencyManager.shared.add { modelContainerForDependency }
        let recipeActionServiceForDependency = environment.recipeActionService
        AppDependencyManager.shared.add { recipeActionServiceForDependency }
        let diaryActionServiceForDependency = environment.diaryActionService
        AppDependencyManager.shared.add { diaryActionServiceForDependency }
        let tagActionServiceForDependency = environment.tagActionService
        AppDependencyManager.shared.add { tagActionServiceForDependency }
        let settingsActionServiceForDependency = environment.settingsActionService
        AppDependencyManager.shared.add { settingsActionServiceForDependency }
    }
}
