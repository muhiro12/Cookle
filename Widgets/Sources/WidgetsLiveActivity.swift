//
//  WidgetsLiveActivity.swift
//  Widgets
//
//  Created by Hiromu Nakano on 2025/09/25.
//

import ActivityKit
import SwiftUI
import WidgetKit

// Live Activity for an ongoing cooking session.
struct CookleCookingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Current step title (e.g. "Boil pasta")
        var stepTitle: String
        // 1-based current step index
        var stepIndex: Int
        // Total number of steps
        var stepCount: Int
    }

    // Fixed properties for the session
    var recipeName: String
}

struct CookleCookingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookleCookingAttributes.self) { context in
            // Lock screen/banner UI
            VStack(alignment: .leading, spacing: 6) {
                Text(context.attributes.recipeName)
                    .font(.headline)
                Text("Step \(context.state.stepIndex)/\(context.state.stepCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.stepTitle)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .activityBackgroundTint(.thinMaterial)
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading) {
                        Text("Cookle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Step \(context.state.stepIndex)/\(context.state.stepCount)")
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
                Text("\(context.state.stepIndex)")
                    .font(.caption2)
            } minimal: {
                Image(systemName: "fork.knife")
            }
            .keylineTint(.accentColor)
        }
    }
}

extension CookleCookingAttributes {
    fileprivate static var preview: CookleCookingAttributes {
        .init(recipeName: "Spaghetti Carbonara")
    }
}

extension CookleCookingAttributes.ContentState {
    fileprivate static var step1: CookleCookingAttributes.ContentState {
        .init(stepTitle: "Boil pasta in salted water", stepIndex: 1, stepCount: 5)
    }
    fileprivate static var step2: CookleCookingAttributes.ContentState {
        .init(stepTitle: "Fry pancetta until crispy", stepIndex: 2, stepCount: 5)
    }
}

#Preview("Cooking", as: .content, using: CookleCookingAttributes.preview) {
    CookleCookingLiveActivity()
} contentStates: {
    CookleCookingAttributes.ContentState.step1
    CookleCookingAttributes.ContentState.step2
}
