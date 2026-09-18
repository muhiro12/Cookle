#if DEBUG
import Foundation

/// Launch-environment configuration for App Store screenshot capture runs.
///
/// Capture runs replace the live store with the app-owned localized sample data so
/// screenshots stay reproducible across locales and device families.
enum CookleCaptureConfiguration {
    private enum EnvironmentKey {
        static let isEnabled = "COOKLE_CAPTURE_MODE"
        static let photoDirectory = "COOKLE_CAPTURE_PHOTO_DIRECTORY"
        static let baseDate = "COOKLE_CAPTURE_BASE_DATE"
        static let screen = "COOKLE_CAPTURE_SCREEN"
    }

    private enum EnabledValue {
        static let enabled = "1"
    }

    /// Indicates whether the current process runs with capture fixtures.
    static var isEnabled: Bool {
        environmentValue(for: EnvironmentKey.isEnabled) == EnabledValue.enabled
    }

    /// Directory holding the sample photo files named by `SamplePhotoAsset`.
    static var photoDirectoryURL: URL? {
        guard let photoDirectoryPath = environmentValue(for: EnvironmentKey.photoDirectory) else {
            return nil
        }
        return .init(
            fileURLWithPath: photoDirectoryPath,
            isDirectory: true
        )
    }

    /// Fixed reference date that keeps visible sample dates deterministic.
    static var baseDate: Date? {
        guard let baseDateValue = environmentValue(for: EnvironmentKey.baseDate) else {
            return nil
        }
        return ISO8601DateFormatter().date(from: baseDateValue)
    }

    /// Screen the capture run opens, so every locale captures the same state.
    static var screen: CookleCaptureScreen {
        guard let screenValue = environmentValue(for: EnvironmentKey.screen),
              let captureScreen = CookleCaptureScreen(rawValue: screenValue) else {
            return .diary
        }
        return captureScreen
    }

    private static func environmentValue(for key: String) -> String? {
        guard let value = ProcessInfo.processInfo.environment[key],
              !value.isEmpty else {
            return nil
        }
        return value
    }
}

#endif
