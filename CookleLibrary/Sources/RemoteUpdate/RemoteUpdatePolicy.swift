import Foundation
import MHPlatformCore

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
    private let activationWindow: MHUpdateActivationWindow

    public var activatedAt: Date {
        activationWindow.activatedAt
    }

    public var expiresAt: Date {
        activationWindow.expiresAt
    }

    /// The shared policy with Cookle's bounded activation and publication requirement.
    public var updatePolicy: MHRemoteUpdatePolicy {
        .init(
            minimumVersion: minimumVersion,
            activationWindow: activationWindow,
            requiresPublicVersion: true
        )
    }

    /// Creates a policy only when its activation window is positive and bounded.
    public init?(
        minimumVersion: AppVersion,
        activatedAt: Date,
        expiresAt: Date
    ) {
        guard let validatedWindow = MHUpdateActivationWindow(
            activatedAt: activatedAt,
            expiresAt: expiresAt,
            maximumDuration: Self.maximumActivationDuration
        ) else {
            return nil
        }

        self.minimumVersion = minimumVersion
        activationWindow = validatedWindow
    }

    /// Returns whether the installed version must update to a confirmed public version.
    public func isUpdateRequired(
        currentVersion: AppVersion,
        publicVersion: AppVersion,
        now: Date
    ) -> Bool {
        updatePolicy.evaluate(
            currentVersion: currentVersion,
            now: now,
            publicVersion: publicVersion
        ) == .updateRequired
    }
}
