import CookleLibrary
import SwiftUI

/// The step position while the timer runs, or the finished message once the
/// activity is stale.
struct CookingTimerStatusText: View {
    let state: CookingTimerActivityState
    let isFinished: Bool

    var body: some View {
        if isFinished {
            Text("Timer Finished")
        } else {
            Text("Step \(state.stepNumber) of \(state.stepCount)")
        }
    }
}
