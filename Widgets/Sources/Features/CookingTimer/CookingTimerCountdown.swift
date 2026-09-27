import CookleLibrary
import SwiftUI

/// A system-driven countdown to the timer deadline, replaced by a bell once
/// the activity is stale.
struct CookingTimerCountdown: View {
    let state: CookingTimerActivityState
    let isFinished: Bool

    var body: some View {
        if isFinished {
            Image(systemName: "bell.fill")
                .accessibilityLabel(Text("Timer Finished"))
        } else {
            Text(
                timerInterval: state.timerStartedAt...max(state.timerStartedAt, state.timerEndsAt),
                countsDown: true
            )
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
        }
    }
}
