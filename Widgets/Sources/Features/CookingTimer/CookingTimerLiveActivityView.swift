import CookleLibrary
import SwiftUI

/// The Lock Screen content of the cooking timer Live Activity.
struct CookingTimerLiveActivityView: View {
    let attributes: CookingTimerActivityAttributes
    let state: CookingTimerActivityState
    let isFinished: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(attributes.recipeName)
                    .font(.headline)
                    .lineLimit(1)
                CookingTimerStatusText(
                    state: state,
                    isFinished: isFinished
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            CookingTimerCountdown(
                state: state,
                isFinished: isFinished
            )
            .font(.system(.largeTitle, design: .rounded).weight(.semibold))
        }
    }
}
