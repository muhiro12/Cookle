import MHUI
import SwiftData
import SwiftUI

struct CookingSessionView: View {
    @Environment(CookingSessionStore.self)
    private var cookingSessionStore
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.mhTheme)
    private var theme
    @State private var isEndSessionConfirmationPresented = false
    @State private var isMealChoicePresented = false
    @State private var isDiaryPresented = false
    @State private var diaryPrefill: DiaryFormPrefill?
    @State private var ingredients = [String]()
    @State private var errorMessage: String?

    var body: some View {
        sessionContent
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton()
                }
            }
            .cookleIdleTimerDisabled()
            .confirmationDialog(
                "End Cooking Session?",
                isPresented: $isEndSessionConfirmationPresented
            ) {
                Button("End and Add to Diary") {
                    isMealChoicePresented = true
                }
                Button("End Session", role: .destructive) {
                    cookingSessionStore.endSession()
                }
                Button("Cancel", role: .cancel) {
                    // Dismisses the alert.
                }
            } message: {
                Text("This stops the active cooking guide and any running timer.")
            }
            .confirmationDialog("Add to Today's Diary", isPresented: $isMealChoicePresented) {
                ForEach(DiaryObjectType.allCases) { type in
                    Button {
                        endAndRecordMeal(type)
                    } label: {
                        Text(type.title)
                    }
                }
            }
            .sheet(isPresented: $isDiaryPresented, onDismiss: dismissCookingView) {
                DiaryFormNavigationView(prefill: diaryPrefill, persistsDraft: false)
            }
            .alert("Cannot Open Diary", isPresented: isErrorPresented) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: cookingSessionStore.activeSnapshot?.updatedAt) {
                guard cookingSessionStore.activeSnapshot == nil,
                      diaryPrefill == nil else {
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

    var readingLayout: AnyLayout {
        if horizontalSizeClass == .regular, !dynamicTypeSize.isAccessibilitySize {
            AnyLayout(HStackLayout(alignment: .top, spacing: theme.spacing.section))
        } else {
            AnyLayout(VStackLayout(alignment: .leading, spacing: theme.spacing.section))
        }
    }

    var isErrorPresented: Binding<Bool> {
        .init(get: { errorMessage != nil }, set: { isPresented in
            if !isPresented {
                errorMessage = nil
            }
        })
    }

    func activeSessionContent(
        snapshot: CookingSessionSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.section) {
            RecipeNameTitle(snapshot.recipeName)
            readingLayout {
                if !ingredients.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.inline) {
                        ForEach(ingredients.indices, id: \.self) { index in
                            Text(verbatim: ingredients[index])
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mhSection("Ingredients")
                }
                CookingStepList(snapshot: snapshot)
            }
            CookingSessionTimerSection(snapshot: snapshot)
            MHActionGroup(layout: .vertical) {
                Button("End Session") {
                    isEndSessionConfirmationPresented = true
                }
                .buttonStyle(.mhSecondary)
            }
        }
        .mhScreen()
        .navigationTitle("Cooking")
        .task(id: snapshot.recipeID) {
            loadIngredients(for: snapshot.recipeID)
        }
    }

    func dismissCookingView() {
        dismiss()
    }

    func loadIngredients(for recipeID: String) {
        ingredients = []
        guard let recipe = try? RecipeStableIdentifierCodec.recipe(from: recipeID, context: context) else {
            return
        }
        ingredients = (recipe.ingredientObjects ?? []).sorted().compactMap { object in
            guard let ingredient = object.ingredient else {
                return nil
            }
            return "\(ingredient.value) \(object.amount)"
        }
    }

    func endAndRecordMeal(_ type: DiaryObjectType) {
        guard let snapshot = cookingSessionStore.activeSnapshot else {
            return
        }
        do {
            guard let recipe = try RecipeStableIdentifierCodec.recipe(from: snapshot.recipeID, context: context) else {
                throw CookleActionError.recipeNotFound
            }
            diaryPrefill = .init(
                date: .now,
                breakfasts: type == .breakfast ? [recipe] : [],
                lunches: type == .lunch ? [recipe] : [],
                dinners: type == .dinner ? [recipe] : [],
                note: ""
            )
            cookingSessionStore.endSession()
            isDiaryPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
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

#if DEBUG
#Preview("Materials and steps") {
    let assembly = DiaryRecipeSelectionPreview.assembly
    let store: CookingSessionStore = {
        let store = CookingSessionStore(persistsSnapshot: false)
        if let recipe = try? assembly.modelContainer.mainContext.fetch(.recipes(.all)).first {
            store.startSession(for: recipe)
        }
        return store
    }()
    NavigationStack {
        CookingSessionView()
            .environment(store)
    }
    .cooklePreviewAppAssembly(assembly)
}
#endif
