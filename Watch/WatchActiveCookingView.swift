import SwiftUI

struct WatchActiveCookingView: View {
    private enum Layout {
        static let contentSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 8
        static let timerFontSize: CGFloat = 30
        static let stepPagerHeight: CGFloat = 150
    }

    @EnvironmentObject private var cookingSessionStore: WatchCookingSessionStore

    private let quickTimerMinutes = [
        1,
        5,
        10
    ]

    var body: some View {
        Group {
            if let activeSnapshot = cookingSessionStore.activeSnapshot {
                ScrollView {
                    VStack(spacing: Layout.contentSpacing) {
                        progressSection(
                            snapshot: activeSnapshot
                        )
                        stepPager(
                            snapshot: activeSnapshot
                        )
                        timerSection(
                            snapshot: activeSnapshot
                        )
                        stepNavigationSection(
                            snapshot: activeSnapshot
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
            } else {
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
        }
        .navigationTitle(
            cookingSessionStore.activeSnapshot?.recipeName ?? "Cooking"
        )
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
            Color.gray.opacity(0.2),
            in: RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    func timerSection(
        snapshot: WatchCookingSessionSnapshot
    ) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            switch snapshot.timerStatus(at: context.date) {
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
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}
