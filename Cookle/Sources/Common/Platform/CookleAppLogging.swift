import CookleLibrary
import Foundation
import MHPlatform
import Observation

@MainActor
@Observable
final class CookleAppLogging {
    private enum Constants {
        static let subsystem = "com.muhiro12.Cookle"
        static let snapshotStorageKeys = MHLogSnapshotStorageKeys(
            current: .init(
                storageKey: "\(CodablePreferenceKey.loggingLastSession.rawValue).current-session"
            ),
            previous: .init(
                storageKey: "\(CodablePreferenceKey.loggingLastSession.rawValue).previous-session"
            )
        )
    }

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
                subsystem: Constants.subsystem,
                snapshotStorageKeys: Constants.snapshotStorageKeys,
                snapshotDefaults: .suite(
                    UserDefaults.appGroupIdentifier
                )
            )
        )
    }

    static func preview() -> CookleAppLogging {
        .init(
            bootstrap: .init(
                captureLevel: .debug,
                subsystem: Constants.subsystem
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
