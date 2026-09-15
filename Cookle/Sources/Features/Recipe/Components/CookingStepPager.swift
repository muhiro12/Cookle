import MHUI
import SwiftUI

struct CookingStepPager: View {
    @Environment(CookingSessionStore.self)
    private var cookingSessionStore
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize
    @Environment(\.mhTheme)
    private var theme

    @ScaledMetric(relativeTo: .title3)
    private var readingHeight: CGFloat = 224

    let snapshot: CookingSessionSnapshot

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Text(snapshot.currentStep ?? "")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            TabView(
                selection: Binding(
                    get: {
                        snapshot.currentStepIndex
                    },
                    set: { stepIndex in
                        cookingSessionStore.setCurrentStepIndex(stepIndex)
                    }
                )
            ) {
                ForEach(Array(snapshot.steps.enumerated()), id: \.offset) { values in
                    ScrollView {
                        Text(values.element)
                            .font(.title3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, theme.spacing.inline)
                    }
                    .tag(values.offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: readingHeight)
        }
    }
}
