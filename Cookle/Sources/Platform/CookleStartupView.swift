import SwiftUI

struct CookleStartupView: View {
    let failureMessage: String?
    let retry: () -> Void

    var body: some View {
        Group {
            if let failureMessage {
                ContentUnavailableView {
                    Label(
                        "Unable to Start Cookle",
                        systemImage: "exclamationmark.triangle"
                    )
                } description: {
                    Text(failureMessage)
                } actions: {
                    Button("Try Again", action: retry)
                }
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

    init(
        failureMessage: String?,
        retry: @escaping () -> Void = {
            // Intentionally empty for previews and isolated presentation.
        }
    ) {
        self.failureMessage = failureMessage
        self.retry = retry
    }
}
