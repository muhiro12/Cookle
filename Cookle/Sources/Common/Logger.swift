import Foundation
@_exported import OSLog

extension Logger {
    init(_ file: String) {
        self.init(
            subsystem: Bundle.main.bundleIdentifier!,
            category: file
        )
    }
}
