import MHUI
import SwiftUI

struct CookingStepList: View {
    @Environment(CookingSessionStore.self)
    private var cookingSessionStore
    @Environment(\.mhTheme)
    private var theme

    let snapshot: CookingSessionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.content) {
            ForEach(Array(snapshot.steps.enumerated()), id: \.offset) { step in
                Button {
                    cookingSessionStore.setCurrentStepIndex(step.offset)
                } label: {
                    HStack(alignment: .top, spacing: theme.spacing.inline) {
                        // The number is how a cook keeps their place in the full
                        // step list, so it uses the primary label role. As
                        // secondary it measured 3.43:1 in light appearance,
                        // below the 4.5:1 WCAG AA threshold for normal text.
                        Text((step.offset + 1).description + ".")
                            .fixedSize()
                        Text(verbatim: step.element)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if snapshot.currentStepIndex == step.offset {
                            Image(systemName: "timer")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(snapshot.currentStepIndex == step.offset ? .isSelected : [])
            }
            Text("Select a step for timer suggestions and Apple Watch.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mhSection("Steps")
    }
}
