import Foundation

/// A short-lived policy that can require an update to a published app version.
public struct RemoteUpdatePolicy: Hashable, Sendable {
    private enum ActivationWindow {
        static let maximumHours = 72
        static let minutesPerHour = 60
        static let secondsPerMinute = 60
    }

    /// The longest activation window accepted from remote configuration.
    public static let maximumActivationDuration = TimeInterval(
        ActivationWindow.maximumHours
            * ActivationWindow.minutesPerHour
            * ActivationWindow.secondsPerMinute
    )

    public let minimumVersion: AppVersion
    public let activatedAt: Date
    public let expiresAt: Date

    /// Creates a policy only when its activation window is positive and bounded.
    public init?(
        minimumVersion: AppVersion,
        activatedAt: Date,
        expiresAt: Date
    ) {
        let activationDuration = expiresAt.timeIntervalSince(activatedAt)
        guard activationDuration.isFinite,
              activationDuration > 0,
              activationDuration <= Self.maximumActivationDuration else {
            return nil
        }

        self.minimumVersion = minimumVersion
        self.activatedAt = activatedAt
        self.expiresAt = expiresAt
    }

    /// Returns whether the installed version must update to a confirmed public version.
    public func isUpdateRequired(
        currentVersion: AppVersion,
        publicVersion: AppVersion,
        now: Date
    ) -> Bool {
        guard now >= activatedAt,
              now <= expiresAt,
              currentVersion < minimumVersion,
              minimumVersion <= publicVersion else {
            return false
        }
        return true
    }
}
