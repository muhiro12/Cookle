import Foundation

private let kCookingSessionMinuteInSeconds = 60

public struct CookingSessionSnapshot: Codable, Equatable, Sendable {
    public let recipeID: String
    public let recipeName: String
    public let steps: [String]
    public let currentStepIndex: Int
    public let activeTimer: CookingSessionTimerSnapshot?
    public let updatedAt: Date
    public let isActive: Bool

    public var stepCount: Int {
        steps.count
    }

    public var currentStep: String? {
        guard steps.indices.contains(currentStepIndex) else {
            return nil
        }

        return steps[currentStepIndex]
    }

    public var currentStepNumber: Int {
        guard stepCount > .zero else {
            return .zero
        }

        return currentStepIndex + 1
    }

    public var hasPreviousStep: Bool {
        currentStepIndex > .zero
    }

    public var hasNextStep: Bool {
        currentStepIndex + 1 < stepCount
    }

    public init(
        recipeID: String,
        recipeName: String,
        steps: [String],
        currentStepIndex: Int,
        activeTimer: CookingSessionTimerSnapshot?,
        updatedAt: Date,
        isActive: Bool
    ) {
        self.recipeID = recipeID
        self.recipeName = recipeName
        self.steps = steps
        self.currentStepIndex = Self.clampedStepIndex(
            currentStepIndex,
            stepCount: steps.count
        )
        self.activeTimer = activeTimer
        self.updatedAt = updatedAt
        self.isActive = isActive
    }

    public init(
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        self.init(
            recipeID: try container.decode(
                String.self,
                forKey: .recipeID
            ),
            recipeName: try container.decode(
                String.self,
                forKey: .recipeName
            ),
            steps: try container.decode(
                [String].self,
                forKey: .steps
            ),
            currentStepIndex: try container.decode(
                Int.self,
                forKey: .currentStepIndex
            ),
            activeTimer: try container.decodeIfPresent(
                CookingSessionTimerSnapshot.self,
                forKey: .activeTimer
            ),
            updatedAt: try container.decode(
                Date.self,
                forKey: .updatedAt
            ),
            isActive: try container.decode(
                Bool.self,
                forKey: .isActive
            )
        )
    }

    public static func decoded(
        from value: String
    ) -> Self? {
        guard let data = value.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(
            Self.self,
            from: data
        )
    }

    private static func clampedStepIndex(
        _ stepIndex: Int,
        stepCount: Int
    ) -> Int {
        guard stepCount > .zero else {
            return .zero
        }

        return min(
            max(stepIndex, .zero),
            stepCount - 1
        )
    }

    public func settingCurrentStepIndex(
        _ stepIndex: Int,
        updatedAt: Date = .now
    ) -> Self {
        .init(
            recipeID: recipeID,
            recipeName: recipeName,
            steps: steps,
            currentStepIndex: stepIndex,
            activeTimer: activeTimer,
            updatedAt: updatedAt,
            isActive: isActive
        )
    }

    public func advancingToNextStep(
        updatedAt: Date = .now
    ) -> Self {
        settingCurrentStepIndex(
            currentStepIndex + 1,
            updatedAt: updatedAt
        )
    }

    public func returningToPreviousStep(
        updatedAt: Date = .now
    ) -> Self {
        settingCurrentStepIndex(
            currentStepIndex - 1,
            updatedAt: updatedAt
        )
    }

    public func startingTimer(
        durationMinutes: Int,
        startedAt: Date = .now
    ) -> Self {
        .init(
            recipeID: recipeID,
            recipeName: recipeName,
            steps: steps,
            currentStepIndex: currentStepIndex,
            activeTimer: .init(
                durationSeconds: durationMinutes * kCookingSessionMinuteInSeconds,
                startedAt: startedAt
            ),
            updatedAt: startedAt,
            isActive: isActive
        )
    }

    public func cancelingTimer(
        updatedAt: Date = .now
    ) -> Self {
        .init(
            recipeID: recipeID,
            recipeName: recipeName,
            steps: steps,
            currentStepIndex: currentStepIndex,
            activeTimer: nil,
            updatedAt: updatedAt,
            isActive: isActive
        )
    }

    public func repeatingTimer(
        startedAt: Date = .now
    ) -> Self {
        guard let activeTimer else {
            return self
        }

        return .init(
            recipeID: recipeID,
            recipeName: recipeName,
            steps: steps,
            currentStepIndex: currentStepIndex,
            activeTimer: .init(
                durationSeconds: activeTimer.durationSeconds,
                startedAt: startedAt
            ),
            updatedAt: startedAt,
            isActive: isActive
        )
    }

    public func endingSession(
        updatedAt: Date = .now
    ) -> Self {
        .init(
            recipeID: recipeID,
            recipeName: recipeName,
            steps: steps,
            currentStepIndex: currentStepIndex,
            activeTimer: nil,
            updatedAt: updatedAt,
            isActive: false
        )
    }

    public func merging(
        with incomingSnapshot: Self
    ) -> Self {
        incomingSnapshot.updatedAt > updatedAt
            ? incomingSnapshot
            : self
    }

    public func timerStatus(
        at date: Date
    ) -> CookingSessionTimerStatus {
        guard let activeTimer else {
            return .inactive
        }

        guard activeTimer.isExpired(at: date) == false else {
            return .expired
        }

        return .running(
            remainingSeconds: activeTimer.remainingSeconds(
                at: date
            )
        )
    }

    public func requiresTimerFollowUp(
        at date: Date
    ) -> Bool {
        timerStatus(at: date) == .expired
    }

    public func encodedString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        guard let data = try? encoder.encode(self) else {
            return nil
        }

        return String(
            data: data,
            encoding: .utf8
        )
    }
}
