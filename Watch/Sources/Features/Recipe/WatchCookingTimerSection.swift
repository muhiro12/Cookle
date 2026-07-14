import SwiftUI

struct WatchCookingTimerSection: View {
    private enum Layout {
        static let minimumHitTargetHeight: CGFloat = 44
        static let sectionSpacing: CGFloat = 8
    }

    private enum TimerValue {
        static let oneMinute = 1
        static let fiveMinutes = 5
        static let tenMinutes = 10
        static let refreshIntervalSeconds = 1
        static let secondsPerMinute = 60
    }

    @EnvironmentObject private var cookingSessionStore: WatchCookingSessionStore
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
    }

    init(
        snapshot: CookingSessionSnapshot
    ) {
        self.snapshot = snapshot
    }
}

private extension WatchCookingTimerSection {
    var timerDisplayDate: Date {
        guard let activeTimer = snapshot.activeTimer else {
            return timerRefreshDate
        }

        return max(
            timerRefreshDate,
            activeTimer.startedAt
        )
    }

    var idleTimerSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Text("Quick Timers")
                .font(.headline)
            if let suggestedTimerMinutes = snapshot.suggestedTimerMinutes {
                Text(
                    "Suggested: \(suggestedTimerMinutes) min"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: Layout.sectionSpacing
            ) {
                ForEach(
                    timerOptions,
                    id: \.self
                ) { minutes in
                    timerButton(
                        minutes: minutes,
                        isSuggested: snapshot.suggestedTimerMinutes == minutes
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var expiredTimerSection: some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Label(
                "Timer Finished",
                systemImage: "bell.fill"
            )
            .font(.headline)
            Button {
                cookingSessionStore.repeatTimer()
            } label: {
                actionButtonLabel("Repeat")
            }
            .buttonStyle(.borderedProminent)
            if snapshot.hasNextStep {
                Button {
                    cookingSessionStore.advanceFromTimerFollowUp()
                } label: {
                    actionButtonLabel("Next Step")
                }
                .buttonStyle(.bordered)
            }
            Button {
                cookingSessionStore.cancelTimer()
            } label: {
                actionButtonLabel("Cancel Timer")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var timerOptions: [Int] {
        let suggestedTimerMinutes = snapshot.suggestedTimerMinutes
        let additionalOptions: [Int] = [
            suggestedTimerMinutes
        ].compactMap { minutes in
            guard let minutes,
                  quickTimerMinutes.contains(
                    where: { value in
                        value == minutes
                    }
                  ) == false else {
                return nil
            }

            return minutes
        }

        return (quickTimerMinutes + additionalOptions).sorted()
    }

    @ViewBuilder
    func timerContent(
        at date: Date
    ) -> some View {
        switch snapshot.timerStatus(at: date) {
        case .inactive:
            idleTimerSection
        case .running(let remainingSeconds):
            runningTimerSection(
                remainingSeconds: remainingSeconds
            )
            .task(id: snapshot.activeTimer) {
                await refreshTimerUntilExpiration()
            }
        case .expired:
            expiredTimerSection
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
                actionButtonLabel("\(minutes) min")
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                cookingSessionStore.startTimer(
                    minutes: minutes
                )
            } label: {
                actionButtonLabel("\(minutes) min")
            }
            .buttonStyle(.bordered)
        }
    }

    func runningTimerSection(
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
                    .title,
                    design: .rounded
                )
                .weight(.semibold)
                .monospacedDigit()
            )
            Button {
                cookingSessionStore.cancelTimer()
            } label: {
                actionButtonLabel("Cancel Timer")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func actionButtonLabel(
        _ title: LocalizedStringKey
    ) -> some View {
        Text(title)
            .frame(
                maxWidth: .infinity,
                minHeight: Layout.minimumHitTargetHeight
            )
            .contentShape(Rectangle())
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
