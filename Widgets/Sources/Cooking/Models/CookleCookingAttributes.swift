import ActivityKit

// Live Activity attributes for an ongoing cooking session.
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

#if DEBUG
extension CookleCookingAttributes {
    static var preview: CookleCookingAttributes {
        .init(recipeName: "Spaghetti Carbonara")
    }
}

extension CookleCookingAttributes.ContentState {
    static var step1: CookleCookingAttributes.ContentState {
        .init(stepTitle: "Boil pasta in salted water", stepIndex: 1, stepCount: 5)
    }
    static var step2: CookleCookingAttributes.ContentState {
        .init(stepTitle: "Fry pancetta until crispy", stepIndex: 2, stepCount: 5)
    }
}
#endif
