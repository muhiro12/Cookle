import SwiftUI

struct WatchActiveCookingView: View {
    private enum Layout {
        static let contentSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 8
        static let timerFontSize: CGFloat = 30
        static let stepPagerHeight: CGFloat = 150
        static let stepPageBackgroundOpacity = 0.2
        static let stepPageCornerRadius: CGFloat = 16
    }

    private enum TimerValue {
        static let oneMinute = 1
        static let fiveMinutes = 5
        static let tenMinutes = 10
        static let refreshIntervalSeconds: TimeInterval = 1
        static let secondsPerMinute = 60
    }

    @EnvironmentObject private var cookingSessionStore: WatchCookingSessionStore

    private let quickTimerMinutes = [
        TimerValue.oneMinute,
        TimerValue.fiveMinutes,
        TimerValue.tenMinutes
    ]

    var body: some View {
        sessionContent()
            .navigationTitle(
                cookingSessionStore.activeSnapshot?.recipeName ?? "Cooking"
            )
    }
}

private extension WatchActiveCookingView {
    @ViewBuilder
    func sessionContent() -> some View {
        if let activeSnapshot = cookingSessionStore.activeSnapshot {
            activeSessionContent(
                snapshot: activeSnapshot
            )
        } else {
            inactiveSessionContent()
        }
    }

    func activeSessionContent(
        snapshot: WatchCookingSessionSnapshot
    ) -> some View {
        ScrollView {
            VStack(spacing: Layout.contentSpacing) {
                progressSection(
                    snapshot: snapshot
                )
                stepPager(
                    snapshot: snapshot
                )
                timerSection(
                    snapshot: snapshot
                )
                stepNavigationSection(
                    snapshot: snapshot
                )
                Button(
                    "End Session",
                    role: .destructive
                ) {
                    cookingSessionStore.endSession()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    func inactiveSessionContent() -> some View {
        VStack(spacing: Layout.sectionSpacing) {
            Image(systemName: "iphone")
                .font(.title2)
                .accessibilityHidden(true)
            Text("Start on iPhone")
                .font(.headline)
            Text(
                "Begin an active cooking session in Cookle on your iPhone."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding()
    }

    func progressSection(
        snapshot: WatchCookingSessionSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Text(
                "Step \(snapshot.currentStepNumber) of \(snapshot.stepCount)"
            )
            .font(.caption)
            ProgressView(
                value: Double(snapshot.currentStepNumber),
                total: Double(max(snapshot.stepCount, 1))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func stepPager(
        snapshot: WatchCookingSessionSnapshot
    ) -> some View {
        TabView(
            selection: Binding(
                get: {
                    snapshot.currentStepIndex
                },
                set: { stepIndex in
                    cookingSessionStore.setCurrentStepIndex(
                        stepIndex
                    )
                }
            )
        ) {
            ForEach(
                Array(snapshot.steps.enumerated()),
                id: \.offset
            ) { values in
                stepPage(
                    stepNumber: values.offset + 1,
                    stepCount: snapshot.stepCount,
                    stepText: values.element
                )
                .tag(values.offset)
            }
        }
        .frame(height: Layout.stepPagerHeight)
    }

    func stepPage(
        stepNumber: Int,
        stepCount: Int,
        stepText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Text(
                "Step \(stepNumber) of \(stepCount)"
            )
            .font(.caption2)
            Text(stepText)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        }
        .padding()
        .background(
            Color.gray.opacity(Layout.stepPageBackgroundOpacity),
            in: RoundedRectangle(
                cornerRadius: Layout.stepPageCornerRadius,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    func timerSection(
        snapshot: WatchCookingSessionSnapshot
    ) -> some View {
        TimelineView(
            .periodic(
                from: .now,
                by: TimerValue.refreshIntervalSeconds
            )
        ) { context in
            timerContent(
                snapshot: snapshot,
                at: context.date
            )
        }
    }

    @ViewBuilder
    func timerContent(
        snapshot: WatchCookingSessionSnapshot,
        at date: Date
    ) -> some View {
        switch snapshot.timerStatus(at: date) {
        case .inactive:
            idleTimerSection(
                snapshot: snapshot
            )
        case .running(let remainingSeconds):
            runningTimerSection(
                remainingSeconds: remainingSeconds
            )
        case .expired:
            expiredTimerSection(
                snapshot: snapshot
            )
        }
    }

    func idleTimerSection(
        snapshot: WatchCookingSessionSnapshot
    ) -> some View {
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
                    timerOptions(
                        for: snapshot
                    ),
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
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                cookingSessionStore.startTimer(
                    minutes: minutes
                )
            } label: {
                Text("\(minutes) min")
                    .frame(maxWidth: .infinity)
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
                    size: Layout.timerFontSize,
                    weight: .semibold,
                    design: .rounded
                )
            )
            Button("Cancel Timer") {
                cookingSessionStore.cancelTimer()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func expiredTimerSection(
        snapshot: WatchCookingSessionSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Label(
                "Timer Finished",
                systemImage: "bell.fill"
            )
            .font(.headline)
            Button("Repeat") {
                cookingSessionStore.repeatTimer()
            }
            .buttonStyle(.borderedProminent)
            if snapshot.hasNextStep {
                Button("Next Step") {
                    cookingSessionStore.advanceFromTimerFollowUp()
                }
                .buttonStyle(.bordered)
            }
            Button("Cancel Timer") {
                cookingSessionStore.cancelTimer()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func stepNavigationSection(
        snapshot: WatchCookingSessionSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Text("Step Navigation")
                .font(.headline)
            HStack(spacing: Layout.sectionSpacing) {
                Button("Prev") {
                    cookingSessionStore.returnToPreviousStep()
                }
                .buttonStyle(.bordered)
                .disabled(snapshot.hasPreviousStep == false)

                Button("Next") {
                    cookingSessionStore.advanceToNextStep()
                }
                .buttonStyle(.borderedProminent)
                .disabled(snapshot.hasNextStep == false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func timerOptions(
        for snapshot: WatchCookingSessionSnapshot
    ) -> [Int] {
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
