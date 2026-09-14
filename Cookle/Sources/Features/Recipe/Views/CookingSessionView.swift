import MHUI
import SwiftUI

struct CookingSessionView: View {
    private enum Layout {
        static let stepCardHeight: CGFloat = 320
    }

    @Environment(CookingSessionStore.self)
    private var cookingSessionStore
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.mhTheme)
    private var theme
    @State private var isEndSessionConfirmationPresented = false

    var body: some View {
        sessionContent
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton()
                }
            }
            .cookleIdleTimerDisabled()
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
            .onChange(of: cookingSessionStore.activeSnapshot?.updatedAt) {
                guard cookingSessionStore.activeSnapshot == nil else {
                    return
                }

                dismiss()
            }
    }
}

private extension CookingSessionView {
    @ViewBuilder var sessionContent: some View {
        if let activeSnapshot = cookingSessionStore.activeSnapshot {
            activeSessionContent(
                snapshot: activeSnapshot
            )
        } else {
            inactiveSessionContent
        }
    }

    var inactiveSessionContent: some View {
        ContentUnavailableView {
            Label(
                "No Active Cooking Session",
                systemImage: "fork.knife"
            )
        } description: {
            Text(
                "Start cooking from a recipe to see the live step guide here."
            )
        }
        .navigationTitle("Cooking")
    }

    func activeSessionContent(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        VStack(spacing: theme.spacing.section) {
            progressSection(
                snapshot: snapshot
            )
            stepPager(
                snapshot: snapshot
            )
            CookingSessionTimerSection(
                snapshot: snapshot
            )
            stepNavigationSection(
                snapshot: snapshot
            )
            MHActionGroup(layout: .vertical) {
                Button(
                    "End Session",
                    role: .destructive
                ) {
                    isEndSessionConfirmationPresented = true
                }
                .buttonStyle(.mhDestructive)
            }
        }
        .mhScreen()
        .navigationTitle(snapshot.recipeName)
    }

    func progressSection(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.inline) {
            Text(
                String(
                    localized: "Step \(snapshot.currentStepNumber) of \(snapshot.stepCount)"
                )
            )
            .font(.headline)
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
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: Layout.stepCardHeight)
    }

    func stepPage(
        stepNumber: Int,
        stepCount: Int,
        stepText: String
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.content) {
                Text(
                    String(
                        localized: "Step \(stepNumber) of \(stepCount)"
                    )
                )
                .font(.headline)
                Text(stepText)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .mhSurfaceInset()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .mhSurface()
    }

    func stepNavigationSection(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        MHActionGroup {
            stepNavigationButtons(
                snapshot: snapshot
            )
        }
        .mhSection("Step Navigation")
    }

    @ViewBuilder
    func stepNavigationButtons(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        Button("Previous Step") {
            cookingSessionStore.returnToPreviousStep()
        }
        .buttonStyle(.mhSecondary)
        .disabled(snapshot.hasPreviousStep == false)

        Button("Next Step") {
            cookingSessionStore.advanceToNextStep()
        }
        .buttonStyle(.mhPrimary)
        .disabled(snapshot.hasNextStep == false)
    }
}

#Preview {
    let store = CookingSessionStore(
        initialSnapshot: .init(
            recipeID: "preview",
            recipeName: "Pasta",
            steps: [
                "Boil water for 10 minutes.",
                "Cook pasta until al dente.",
                "Serve immediately."
            ],
            currentStepIndex: 1,
            activeTimer: .init(
                durationSeconds: 300,
                startedAt: Date.now.addingTimeInterval(-120)
            ),
            updatedAt: .now,
            isActive: true
        ),
        persistsSnapshot: false
    )

    NavigationStack {
        CookingSessionView()
            .environment(store)
    }
}
