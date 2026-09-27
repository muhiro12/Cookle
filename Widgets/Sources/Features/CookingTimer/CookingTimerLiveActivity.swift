import ActivityKit
import CookleLibrary
import SwiftUI
import WidgetKit

/// The Lock Screen and Dynamic Island presentation of the active cooking
/// timer. The system counts down to the deadline without the app running;
/// once the deadline passes the activity is stale and says the timer ended.
struct CookingTimerLiveActivity: Widget {
    private enum Layout {
        static let compactTimerWidth: CGFloat = 48
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookingTimerActivityAttributes.self) { context in
            CookingTimerLiveActivityView(
                attributes: context.attributes,
                state: context.state,
                isFinished: context.isStale
            )
            .padding()
            .widgetURL(recipeURL(for: context.attributes))
        } dynamicIsland: { context in
            dynamicIsland(for: context)
        }
    }

    private func dynamicIsland(
        for context: ActivityViewContext<CookingTimerActivityAttributes>
    ) -> DynamicIsland {
        DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                Label {
                    Text(context.attributes.recipeName)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "fork.knife")
                }
            }
            DynamicIslandExpandedRegion(.trailing) {
                CookingTimerCountdown(state: context.state, isFinished: context.isStale)
                    .font(.title3.weight(.semibold))
            }
            DynamicIslandExpandedRegion(.bottom) {
                CookingTimerStatusText(state: context.state, isFinished: context.isStale)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } compactLeading: {
            Image(systemName: context.isStale ? "bell.fill" : "timer")
        } compactTrailing: {
            CookingTimerCountdown(state: context.state, isFinished: context.isStale)
                .frame(maxWidth: Layout.compactTimerWidth)
        } minimal: {
            Image(systemName: context.isStale ? "bell.fill" : "timer")
        }
        .widgetURL(recipeURL(for: context.attributes))
    }

    private func recipeURL(
        for attributes: CookingTimerActivityAttributes
    ) -> URL {
        CookleDeepLinkURLBuilder.preferredRecipeDetailURL(
            for: attributes.recipeID
        )
    }
}

#Preview(
    "Lock Screen",
    as: .content,
    using: CookingTimerActivityAttributes(
        sessionKey: "preview.1",
        recipeID: "preview",
        recipeName: "Pasta"
    )
) {
    CookingTimerLiveActivity()
} contentStates: {
    CookingTimerActivityState(
        timerStartedAt: .now,
        timerEndsAt: .now.addingTimeInterval(300),
        stepNumber: 2,
        stepCount: 5
    )
}
