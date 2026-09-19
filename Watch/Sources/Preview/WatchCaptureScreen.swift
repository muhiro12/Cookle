#if DEBUG
/// Screens a Watch capture run opens without simulated user interaction.
enum WatchCaptureScreen: String {
    case cookingStep
    case cookingTimers
    case cookingEmpty

    /// Indicates whether the capture run starts scrolled to the timer and navigation controls.
    var scrollsToTimerSection: Bool {
        self == .cookingTimers
    }

    /// Indicates whether the capture run keeps the session inactive to show the empty state.
    var showsInactiveSession: Bool {
        self == .cookingEmpty
    }
}
#endif
