import CookleLibrary
import Foundation
import MHPlatform
import Observation

@MainActor
@Observable
final class CookleAppLogging {
    nonisolated private static let subsystem = "com.muhiro12.Cookle"
    nonisolated static let snapshotStorageDescriptors = MHLogSnapshotStorageDescriptors(
        current: .init(
            storageKey: CookleUserDefaultsKeys.Standard.currentLogSnapshot.rawValue,
            defaultSelection: .standard
        ),
        previous: .init(
            storageKey: CookleUserDefaultsKeys.Standard.previousLogSnapshot.rawValue,
            defaultSelection: .standard
        )
    )

    let bootstrap: MHLoggingBootstrap

    init(
        bootstrap: MHLoggingBootstrap
    ) {
        self.bootstrap = bootstrap
    }

    static func live() -> CookleAppLogging {
        let snapshotStore = MHPreferenceStore(
            userDefaults: .standard
        )
        return .init(
            bootstrap: .init(
                snapshotStore: snapshotStore,
                captureLevel: captureLevel,
                subsystem: subsystem,
                snapshotStorageDescriptors: snapshotStorageDescriptors
            )
        )
    }

    static func preview() -> CookleAppLogging {
        .init(
            bootstrap: .init(
                captureLevel: .debug,
                subsystem: subsystem
            )
        )
    }

    func logger(
        category: String,
        source: String = #fileID
    ) -> MHLogger {
        bootstrap.logger(
            category: category,
            source: source
        )
    }
}

private extension CookleAppLogging {
    static var captureLevel: MHLogLevel {
        #if DEBUG
        .info
        #else
        .warning
        #endif
    }
}
