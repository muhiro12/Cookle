import CookleLibrary
import Foundation
import MHPlatform
import Observation

@MainActor
@Observable
final class CookleAppLogging {
    private static let subsystem = "com.muhiro12.Cookle"
    private static let snapshotStore = MHPreferenceStore(
        userDefaults: .standard
    )
    nonisolated static let snapshotStorageDescriptors = MHLogSnapshotStorageDescriptors(
        current: .init(
            storageKey: CodablePreferenceKey.loggingLastSession.storageKey(
                suffix: "current-session"
            ),
            defaultSelection: .standard
        ),
        previous: .init(
            storageKey: CodablePreferenceKey.loggingLastSession.storageKey(
                suffix: "previous-session"
            ),
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
        .init(
            bootstrap: .init(
                captureLevel: captureLevel,
                subsystem: subsystem,
                snapshotStorageDescriptors: snapshotStorageDescriptors,
                snapshotStore: snapshotStore
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
