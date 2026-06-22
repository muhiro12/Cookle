import Foundation

private let kCookingSessionTimerSecondsPerMinute = 60

public struct CookingSessionTimerSnapshot: Codable, Equatable, Sendable {
    public let durationSeconds: Int
    public let startedAt: Date

    public var endsAt: Date {
        startedAt.addingTimeInterval(
            TimeInterval(durationSeconds)
        )
    }

    public var durationMinutes: Int {
        durationSeconds / kCookingSessionTimerSecondsPerMinute
    }

    public init(
        durationSeconds: Int,
        startedAt: Date
    ) {
        self.durationSeconds = max(durationSeconds, .zero)
        self.startedAt = startedAt
    }

    public func remainingSeconds(
        at date: Date
    ) -> Int {
        max(
            Int(ceil(endsAt.timeIntervalSince(date))),
            .zero
        )
    }

    public func isExpired(
        at date: Date
    ) -> Bool {
        date >= endsAt
    }
}
