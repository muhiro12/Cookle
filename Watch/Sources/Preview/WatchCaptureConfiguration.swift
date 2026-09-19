#if DEBUG
import Foundation

/// Launch-environment configuration for App Store screenshot capture runs on Apple Watch.
///
/// Capture runs replace the companion connection with a fixed cooking session snapshot
/// so screenshots stay reproducible across locales.
enum WatchCaptureConfiguration {
    private enum EnvironmentKey {
        static let isEnabled = "COOKLE_CAPTURE_MODE"
        static let screen = "COOKLE_CAPTURE_SCREEN"
        static let snapshot = "COOKLE_CAPTURE_SNAPSHOT"
    }

    private enum EnabledValue {
        static let enabled = "1"
    }

    /// Indicates whether the current process runs with capture fixtures.
    static var isEnabled: Bool {
        environmentValue(for: EnvironmentKey.isEnabled) == EnabledValue.enabled
    }

    /// Screen the capture run opens, so every locale captures the same state.
    static var screen: WatchCaptureScreen {
        guard let screenValue = environmentValue(for: EnvironmentKey.screen),
              let captureScreen = WatchCaptureScreen(rawValue: screenValue) else {
            return .cookingStep
        }
        return captureScreen
    }

    /// Cooking session decoded from the same payload the companion app delivers.
    static var snapshot: CookingSessionSnapshot? {
        guard !screen.showsInactiveSession,
              let encodedSnapshot = environmentValue(for: EnvironmentKey.snapshot) else {
            return nil
        }
        return CookingSessionSnapshot.decoded(from: encodedSnapshot)
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
