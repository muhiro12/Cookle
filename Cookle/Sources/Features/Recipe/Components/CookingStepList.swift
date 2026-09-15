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
                        Text((step.offset + 1).description + ".")
                            .foregroundStyle(.secondary)
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
