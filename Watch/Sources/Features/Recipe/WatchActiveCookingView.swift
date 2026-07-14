import SwiftUI

struct WatchActiveCookingView: View {
    private enum Layout {
        static let baseStepPagerHeight: CGFloat = 150
        static let contentSpacing: CGFloat = 12
        static let minimumHitTargetHeight: CGFloat = 44
        static let sectionSpacing: CGFloat = 8
        static let stepPageBackgroundOpacity = 0.2
        static let stepPageCornerRadius: CGFloat = 16
    }

    @EnvironmentObject private var cookingSessionStore: WatchCookingSessionStore
    @ScaledMetric(relativeTo: .body)
    private var stepPagerHeight = Layout.baseStepPagerHeight

    @State private var isEndSessionConfirmationPresented = false

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
    }
}

private extension WatchActiveCookingView {
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
                progressSection(
                    snapshot: snapshot
                )
                stepPager(
                    snapshot: snapshot
                )
                WatchCookingTimerSection(
                    snapshot: snapshot
                )
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
                .tag(values.offset)
            }
        }
        .frame(height: stepPagerHeight)
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
