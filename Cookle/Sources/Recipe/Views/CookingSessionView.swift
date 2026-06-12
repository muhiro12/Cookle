import SwiftUI

struct CookingSessionView: View {
    private enum Layout {
        static let contentSpacing: CGFloat = 24
        static let screenPadding: CGFloat = 20
        static let progressSpacing: CGFloat = 8
        static let stepCardHeight: CGFloat = 320
        static let sectionCornerRadius: CGFloat = 24
        static let sectionPadding: CGFloat = 20
        static let buttonSpacing: CGFloat = 12
    }

    @Environment(CookingSessionStore.self)
    private var cookingSessionStore
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        sessionContent
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton()
                }
            }
            .cookleIdleTimerDisabled()
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
        ScrollView {
            VStack(spacing: Layout.contentSpacing) {
                progressSection(
                    snapshot: snapshot
                )
                stepPager(
                    snapshot: snapshot
                )
                sectionContainer {
                    CookingSessionTimerSection(
                        snapshot: snapshot
                    )
                }
                sectionContainer {
                    stepNavigationSection(
                        snapshot: snapshot
                    )
                }
                Button(
                    "End Session",
                    role: .destructive
                ) {
                    cookingSessionStore.endSession()
                }
                .cookleGlassButtonStyle(isProminent: true)
            }
            .padding(Layout.screenPadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(snapshot.recipeName)
    }

    func progressSection(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.progressSpacing) {
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
            VStack(alignment: .leading, spacing: Layout.buttonSpacing) {
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
            .padding(Layout.sectionPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .cookleGlassSurface(
            in: RoundedRectangle(
                cornerRadius: Layout.sectionCornerRadius,
                style: .continuous
            )
        )
    }

    func stepNavigationSection(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.buttonSpacing) {
            Text("Step Navigation")
                .font(.headline)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Layout.buttonSpacing) {
                    stepNavigationButtons(
                        snapshot: snapshot
                    )
                }
                VStack(spacing: Layout.buttonSpacing) {
                    stepNavigationButtons(
                        snapshot: snapshot
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func stepNavigationButtons(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        Button("Previous Step") {
            cookingSessionStore.returnToPreviousStep()
        }
        .cookleGlassButtonStyle()
        .disabled(snapshot.hasPreviousStep == false)

        Button("Next Step") {
            cookingSessionStore.advanceToNextStep()
        }
        .cookleGlassButtonStyle(isProminent: true)
        .disabled(snapshot.hasNextStep == false)
    }

    func sectionContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(Layout.sectionPadding)
            .cookleGlassSurface(
                in: RoundedRectangle(
                    cornerRadius: Layout.sectionCornerRadius,
                    style: .continuous
                )
            )
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
