import Foundation

struct WatchCookingSessionSnapshot: Codable, Equatable {
    enum TimerStatus: Equatable {
        case inactive
        case running(remainingSeconds: Int)
        case expired
    }

    struct TimerSnapshot: Codable, Equatable {
        let durationSeconds: Int
        let startedAt: Date

        var endsAt: Date {
            startedAt.addingTimeInterval(
                TimeInterval(durationSeconds)
            )
        }

        var durationMinutes: Int {
            durationSeconds / 60
        }

        init(
            durationSeconds: Int,
            startedAt: Date
        ) {
            self.durationSeconds = max(durationSeconds, .zero)
            self.startedAt = startedAt
        }

        func remainingSeconds(
            at date: Date
        ) -> Int {
            max(
                Int(ceil(endsAt.timeIntervalSince(date))),
                .zero
            )
        }

        func isExpired(
            at date: Date
        ) -> Bool {
            date >= endsAt
        }
    }

    let recipeID: String
    let recipeName: String
    let steps: [String]
    let currentStepIndex: Int
    let activeTimer: TimerSnapshot?
    let updatedAt: Date
    let isActive: Bool

    var stepCount: Int {
        steps.count
    }

    var currentStep: String? {
        guard steps.indices.contains(currentStepIndex) else {
            return nil
        }

        return steps[currentStepIndex]
    }

    var currentStepNumber: Int {
        guard stepCount > .zero else {
            return .zero
        }

        return currentStepIndex + 1
    }

    var hasPreviousStep: Bool {
        currentStepIndex > .zero
    }

    var hasNextStep: Bool {
        currentStepIndex + 1 < stepCount
    }

    var suggestedTimerMinutes: Int? {
        guard let currentStep else {
            return nil
        }

        return Self.parseSuggestedTimerMinutes(
            from: currentStep
        )
    }

    init(
        recipeID: String,
        recipeName: String,
        steps: [String],
        currentStepIndex: Int,
        activeTimer: TimerSnapshot?,
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

    init(
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
                TimerSnapshot.self,
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

    static func decoded(
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

    private static func parseSuggestedTimerMinutes(
        from step: String
    ) -> Int? {
        let normalizedStep = (step.applyingTransform(
            .fullwidthToHalfwidth,
            reverse: false
        ) ?? step).lowercased()
        let minutePattern = #"(\d+)\s*(?:min|mins|minute|minutes|分)"#

        guard let matchedRange = normalizedStep.range(
            of: minutePattern,
            options: .regularExpression
        ) else {
            return nil
        }

        let matchedText = String(
            normalizedStep[matchedRange]
        )
        let digits = matchedText
            .components(
                separatedBy: CharacterSet.decimalDigits.inverted
            )
            .joined()
        guard let minutes = Int(digits),
              minutes > .zero else {
            return nil
        }

        return minutes
    }

    func settingCurrentStepIndex(
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

    func advancingToNextStep(
        updatedAt: Date = .now
    ) -> Self {
        settingCurrentStepIndex(
            currentStepIndex + 1,
            updatedAt: updatedAt
        )
    }

    func returningToPreviousStep(
        updatedAt: Date = .now
    ) -> Self {
        settingCurrentStepIndex(
            currentStepIndex - 1,
            updatedAt: updatedAt
        )
    }

    func startingTimer(
        durationMinutes: Int,
        startedAt: Date = .now
    ) -> Self {
        .init(
            recipeID: recipeID,
            recipeName: recipeName,
            steps: steps,
            currentStepIndex: currentStepIndex,
            activeTimer: .init(
                durationSeconds: durationMinutes * 60,
                startedAt: startedAt
            ),
            updatedAt: startedAt,
            isActive: isActive
        )
    }

    func cancelingTimer(
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

    func repeatingTimer(
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

    func endingSession(
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

    func merging(
        with incomingSnapshot: Self
    ) -> Self {
        incomingSnapshot.updatedAt > updatedAt
            ? incomingSnapshot
            : self
    }

    func timerStatus(
        at date: Date
    ) -> TimerStatus {
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

    func encodedString() -> String? {
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
