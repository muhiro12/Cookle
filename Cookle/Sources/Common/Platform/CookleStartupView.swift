import SwiftUI

struct CookleStartupView: View {
    let failureMessage: String?

    var body: some View {
        Group {
            if let failureMessage {
                ContentUnavailableView(
                    "Unable to Start Cookle",
                    systemImage: "exclamationmark.triangle",
                    description: Text(failureMessage)
                )
            } else {
                ProgressView("Loading Cookle")
                    .progressViewStyle(.circular)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}
