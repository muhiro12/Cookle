import SwiftUI

struct WatchActiveCookingView: View {
    private enum Layout {
        static let baseStepPagerHeight: CGFloat = 150
        static let contentInset: CGFloat = 10
        static let contentSpacing: CGFloat = 12
        static let minimumHitTargetHeight: CGFloat = 44
        static let sectionSpacing: CGFloat = 8
        static let stepPageBackgroundOpacity = 0.2
        static let stepPageCornerRadius: CGFloat = 16
        static let timerSectionID = "timerSection"
    }

    @EnvironmentObject private var cookingSessionStore: WatchCookingSessionStore
    @ScaledMetric(relativeTo: .body)
    private var stepPagerHeight = Layout.baseStepPagerHeight

    @State private var isEndSessionConfirmationPresented = false
    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        sessionContent()
            .navigationTitle(sessionNavigationTitle)
            .alert(
                "End Cooking Session?",
                isPresented: $isEndSessionConfirmationPresented
            ) {
                Button("End Session", role: .destructive) {
                    cookingSessionStore.endSession()
                }
                Button("Cancel", role: .cancel) {
                    // Dismisses the alert.
                }
            } message: {
                Text("This stops the active cooking guide and any running timer.")
            }
            .onChange(of: hasActiveSession) { _, hasActiveSession in
                // A session ended here or from iPhone leaves nothing to confirm.
                guard hasActiveSession == false else {
                    return
                }
                isEndSessionConfirmationPresented = false
            }
    }
}

private extension WatchActiveCookingView {
    var hasActiveSession: Bool {
        cookingSessionStore.activeSnapshot != nil
    }

    var sessionNavigationTitle: Text {
        guard let recipeName = cookingSessionStore.activeSnapshot?.recipeName else {
            return Text("Cooking")
        }

        return Text(verbatim: recipeName)
    }

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
        snapshot: CookingSessionSnapshot
    ) -> some View {
        ScrollView {
            VStack(spacing: Layout.contentSpacing) {
                WatchCookingSyncNotice()
                progressSection(
                    snapshot: snapshot
                )
                stepPager(
                    snapshot: snapshot
                )
                WatchCookingTimerSection(
                    snapshot: snapshot
                )
                .id(Layout.timerSectionID)
                stepNavigationSection(
                    snapshot: snapshot
                )
                Button(role: .destructive) {
                    isEndSessionConfirmationPresented = true
                } label: {
                    actionButtonLabel("End Session")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(Layout.contentInset)
        }
        .scrollPosition($scrollPosition)
        .task {
            scrollToCaptureSectionIfNeeded()
        }
    }

    /// Places the capture run at the timer controls without simulated user interaction.
    func scrollToCaptureSectionIfNeeded() {
        #if DEBUG
        guard WatchCaptureConfiguration.isEnabled,
              WatchCaptureConfiguration.screen.scrollsToTimerSection else {
            return
        }
        scrollPosition.scrollTo(
            id: Layout.timerSectionID,
            anchor: .top
        )
        #endif
    }

    func inactiveSessionContent() -> some View {
        WatchRecentRecipesView()
    }

    func progressSection(
        snapshot: CookingSessionSnapshot
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
        snapshot: CookingSessionSnapshot
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
                .padding(.horizontal, Layout.contentInset)
                .tag(values.offset)
            }
        }
        .frame(height: stepPagerHeight)
        .padding(.horizontal, -Layout.contentInset)
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
            ScrollView(.vertical) {
                Text(stepText)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .topLeading
                    )
            }
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

    func stepNavigationSection(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
            Text("Step Navigation")
                .font(.headline)
            HStack(spacing: Layout.sectionSpacing) {
                Button {
                    cookingSessionStore.returnToPreviousStep()
                } label: {
                    actionButtonLabel("Prev")
                }
                .buttonStyle(.bordered)
                .disabled(snapshot.hasPreviousStep == false)

                Button {
                    cookingSessionStore.advanceToNextStep()
                } label: {
                    actionButtonLabel("Next")
                }
                .buttonStyle(.borderedProminent)
                .disabled(snapshot.hasNextStep == false)
            }
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
}
