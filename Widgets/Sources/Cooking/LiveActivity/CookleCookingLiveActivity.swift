import SwiftUI
import WidgetKit

struct CookleCookingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookleCookingAttributes.self) { context in
            // Lock screen/banner UI
            VStack(alignment: .leading, spacing: 6) {
                Text(context.attributes.recipeName)
                    .font(.headline)
                Text("Step \\ (context.state.stepIndex)/\\(context.state.stepCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.stepTitle)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .activityBackgroundTint(.secondary)
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Cookle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Step \\ (context.state.stepIndex)/\\(context.state.stepCount)")
                            .font(.caption)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "fork.knife")
                        .symbolRenderingMode(.monochrome)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.recipeName)
                            .font(.subheadline)
                            .bold()
                        Text(context.state.stepTitle)
                            .font(.footnote)
                            .lineLimit(2)
                    }
                }
            } compactLeading: {
                Image(systemName: "fork.knife")
            } compactTrailing: {
                Text("\\(context.state.stepIndex)")
                    .font(.caption2)
            } minimal: {
                Image(systemName: "fork.knife")
            }
            .keylineTint(.accentColor)
        }
    }
}

#if DEBUG
#Preview("Cooking", as: .content, using: CookleCookingAttributes.preview) {
    CookleCookingLiveActivity()
} contentStates: {
    CookleCookingAttributes.ContentState.step1
    CookleCookingAttributes.ContentState.step2
}
#endif
