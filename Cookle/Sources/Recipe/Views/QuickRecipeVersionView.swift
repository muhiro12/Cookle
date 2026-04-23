import SwiftData
import SwiftUI

@available(iOS 26.0, *)
struct QuickRecipeVersionView: View {
    private enum DisplayMode {
        case quick
        case full
    }

    @Environment(\.dismiss)
    private var dismiss

    let recipe: Recipe
    let quickVersion: QuickRecipeVersion

    @State private var displayMode = DisplayMode.quick

    var body: some View {
        List {
            displayModeSection
            switch displayMode {
            case .quick:
                quickVersionSections
            case .full:
                fullVersionSections
            }
            explanationSection
        }
        .navigationTitle(Text("Quick Version"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

@available(iOS 26.0, *)
private extension QuickRecipeVersionView {
    var displayModeSection: some View {
        Section {
            Picker("Version", selection: $displayMode) {
                Text("Quick").tag(DisplayMode.quick)
                Text("Full").tag(DisplayMode.full)
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder var quickVersionSections: some View {
        Section("Summary") {
            Text(quickVersion.summary)
            if quickVersion.estimatedCookingTime > .zero {
                Label(
                    "\(quickVersion.estimatedCookingTime) min",
                    systemImage: "clock"
                )
            }
        }
        stepsSection(
            title: "Quick Steps",
            steps: quickVersion.steps
        )
    }

    @ViewBuilder var fullVersionSections: some View {
        if recipe.cookingTime > .zero {
            Section("Original Cooking Time") {
                Label(
                    "\(recipe.cookingTime) min",
                    systemImage: "clock"
                )
            }
        }
        stepsSection(
            title: "Full Steps",
            steps: recipe.steps
        )
    }

    var explanationSection: some View {
        Section {
            Text("This quick version is temporary. The original recipe is unchanged.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    func stepsSection(
        title: LocalizedStringKey,
        steps: [String]
    ) -> some View {
        Section(title) {
            ForEach(Array(steps.enumerated()), id: \.offset) { values in
                HStack(alignment: .top) {
                    Text((values.offset + RecipeStepLayout.stepNumberOffset).description + ".")
                        .foregroundStyle(.secondary)
                        .frame(width: RecipeStepLayout.indexWidth)
                    Text(values.element)
                }
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    if #available(iOS 26.0, *) {
        NavigationStack {
            QuickRecipeVersionView(
                recipe: recipes[0],
                quickVersion: .init(
                    summary: "A shorter view for quick reference.",
                    estimatedCookingTime: 10,
                    steps: [
                        "Prep ingredients.",
                        "Cook and finish."
                    ]
                )
            )
        }
    }
}
