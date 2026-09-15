import MHUI
import SwiftUI

struct CookingSessionTimerSection: View {
    private enum TimerValue {
        static let oneMinute = 1
        static let fiveMinutes = 5
        static let refreshIntervalSeconds = 1
        static let tenMinutes = 10
        static let secondsPerMinute = 60
    }

    @Environment(CookingSessionStore.self)
    private var cookingSessionStore
    @Environment(\.mhTheme)
    private var theme

    @State private var timerRefreshDate = Date.now

    private let snapshot: CookingSessionSnapshot

    private let quickTimerMinutes = [
        TimerValue.oneMinute,
        TimerValue.fiveMinutes,
        TimerValue.tenMinutes
    ]

    var body: some View {
        timerContent(
            at: timerDisplayDate
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSection("Quick Timers")
    }

    init(
        snapshot: CookingSessionSnapshot
    ) {
        self.snapshot = snapshot
    }
}

private extension CookingSessionTimerSection {
    var timerDisplayDate: Date {
        guard let activeTimer = snapshot.activeTimer else {
            return timerRefreshDate
        }

        return max(
            timerRefreshDate,
            activeTimer.startedAt
        )
    }

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
        VStack(alignment: .leading, spacing: theme.spacing.content) {
            if let suggestedTimer {
                Text(
                    String(
                        localized: "Suggested from this step: \(suggestedTimer.minutes) min"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Text("Step \(snapshot.currentStepNumber) of \(snapshot.stepCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            timerButtons
        }
    }

    var timerButtons: some View {
        MHActionGroup {
            timerButtonRow
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
        VStack(alignment: .leading, spacing: theme.spacing.content) {
            Label("Timer Finished", systemImage: "bell.fill")
                .font(.headline)
            MHActionGroup {
                expiredActionButtons
            }
        }
    }

    @ViewBuilder var expiredActionButtons: some View {
        Button("Repeat") {
            cookingSessionStore.repeatTimer()
        }
        .buttonStyle(.mhPrimary)

        Button("Cancel Timer") {
            cookingSessionStore.cancelTimer()
        }
        .buttonStyle(.mhSecondary)
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
            .task(id: snapshot.activeTimer) {
                await refreshTimerUntilExpiration()
            }
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
            }
            .buttonStyle(.mhPrimary)
        } else {
            Button {
                cookingSessionStore.startTimer(
                    minutes: minutes
                )
            } label: {
                Text("\(minutes) min")
            }
            .buttonStyle(.mhSecondary)
        }
    }

    func runningTimerContent(
        remainingSeconds: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.content) {
            Text("Timer Running")
                .font(.headline)
            Text(
                formattedDuration(
                    remainingSeconds: remainingSeconds
                )
            )
            .font(
                .system(
                    .largeTitle,
                    design: .rounded
                )
                .weight(.semibold)
                .monospacedDigit()
            )
            Button(
                "Cancel Timer",
                role: .destructive
            ) {
                cookingSessionStore.cancelTimer()
            }
            .buttonStyle(.mhDestructive)
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

    @MainActor
    func refreshTimerUntilExpiration() async {
        while Task.isCancelled == false {
            let currentDate = Date.now
            timerRefreshDate = currentDate

            guard case .running = snapshot.timerStatus(
                at: currentDate
            ) else {
                return
            }

            do {
                try await Task.sleep(
                    for: .seconds(TimerValue.refreshIntervalSeconds)
                )
            } catch {
                return
            }
        }
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
