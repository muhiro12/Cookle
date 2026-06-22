import SwiftUI

struct CookingSessionTimerSection: View {
    private enum Layout {
        static let buttonSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 16
        static let timerValueFontSize: CGFloat = 42
        static let timerValueWeight = Font.Weight.semibold
    }

    private enum TimerValue {
        static let oneMinute = 1
        static let fiveMinutes = 5
        static let tenMinutes = 10
        static let secondsPerMinute = 60
    }

    @Environment(CookingSessionStore.self)
    private var cookingSessionStore

    private let snapshot: CookingSessionSnapshot

    private let quickTimerMinutes = [
        TimerValue.oneMinute,
        TimerValue.fiveMinutes,
        TimerValue.tenMinutes
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Text("Quick Timers")
                .font(.headline)
            TimelineView(.periodic(from: .now, by: 1)) { context in
                timerContent(
                    at: context.date
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    init(
        snapshot: CookingSessionSnapshot
    ) {
        self.snapshot = snapshot
    }
}

private extension CookingSessionTimerSection {
    var suggestedTimer: CookingTimerSuggestion? {
        guard let currentStep = snapshot.currentStep else {
            return nil
        }

        return CookingTimerSuggestionParser.suggestedTimer(
            for: currentStep
        )
    }

    var timerOptions: [Int] {
        let suggestedMinutes = suggestedTimer?.minutes
        let combinedOptions = quickTimerMinutes + [
            suggestedMinutes
        ].compactMap { minutes in
            guard let minutes,
                  quickTimerMinutes.contains(minutes) == false else {
                return nil
            }

            return minutes
        }
        return combinedOptions.sorted()
    }

    var idleTimerContent: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            if let suggestedTimer {
                Text(
                    String(
                        localized: "Suggested from this step: \(suggestedTimer.minutes) min"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            timerButtons
        }
    }

    var timerButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Layout.buttonSpacing) {
                timerButtonRow
            }
            VStack(spacing: Layout.buttonSpacing) {
                timerButtonRow
            }
        }
    }

    var timerButtonRow: some View {
        ForEach(timerOptions, id: \.self) { minutes in
            timerButton(
                minutes: minutes,
                isSuggested: suggestedTimer?.minutes == minutes
            )
        }
    }

    var expiredTimerContent: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Label("Timer Finished", systemImage: "bell.fill")
                .font(.headline)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Layout.buttonSpacing) {
                    expiredActionButtons
                }
                VStack(spacing: Layout.buttonSpacing) {
                    expiredActionButtons
                }
            }
        }
    }

    @ViewBuilder var expiredActionButtons: some View {
        Button("Repeat") {
            cookingSessionStore.repeatTimer()
        }
        .cookleGlassButtonStyle(isProminent: true)

        if snapshot.hasNextStep {
            Button("Next Step") {
                cookingSessionStore.advanceFromTimerFollowUp()
            }
            .cookleGlassButtonStyle()
        }

        Button("Cancel Timer") {
            cookingSessionStore.cancelTimer()
        }
        .cookleGlassButtonStyle()
    }

    @ViewBuilder
    func timerContent(
        at date: Date
    ) -> some View {
        switch snapshot.timerStatus(at: date) {
        case .inactive:
            idleTimerContent
        case .running(let remainingSeconds):
            runningTimerContent(
                remainingSeconds: remainingSeconds
            )
        case .expired:
            expiredTimerContent
        }
    }

    @ViewBuilder
    func timerButton(
        minutes: Int,
        isSuggested: Bool
    ) -> some View {
        if isSuggested {
            Button {
                cookingSessionStore.startTimer(
                    minutes: minutes
                )
            } label: {
                Text("\(minutes) min")
                    .frame(maxWidth: .infinity)
            }
            .cookleGlassButtonStyle(isProminent: true)
        } else {
            Button {
                cookingSessionStore.startTimer(
                    minutes: minutes
                )
            } label: {
                Text("\(minutes) min")
                    .frame(maxWidth: .infinity)
            }
            .cookleGlassButtonStyle()
        }
    }

    func runningTimerContent(
        remainingSeconds: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Text("Timer Running")
                .font(.headline)
            Text(
                formattedDuration(
                    remainingSeconds: remainingSeconds
                )
            )
            .font(
                .system(
                    size: Layout.timerValueFontSize,
                    weight: Layout.timerValueWeight,
                    design: .rounded
                )
            )
            Button(
                "Cancel Timer",
                role: .destructive
            ) {
                cookingSessionStore.cancelTimer()
            }
            .cookleGlassButtonStyle()
        }
    }

    func formattedDuration(
        remainingSeconds: Int
    ) -> String {
        let minutes = remainingSeconds / TimerValue.secondsPerMinute
        let seconds = remainingSeconds % TimerValue.secondsPerMinute
        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}

#Preview {
    let store = CookingSessionStore(
        initialSnapshot: .init(
            recipeID: "preview",
            recipeName: "Pasta",
            steps: [
                "Boil water for 10 min.",
                "Cook pasta."
            ],
            currentStepIndex: 0,
            activeTimer: nil,
            updatedAt: .now,
            isActive: true
        ),
        persistsSnapshot: false
    )

    NavigationStack {
        if let activeSnapshot = store.activeSnapshot {
            CookingSessionTimerSection(
                snapshot: activeSnapshot
            )
            .padding()
            .environment(store)
        }
    }
}
