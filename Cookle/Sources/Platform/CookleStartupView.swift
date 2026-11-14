import SwiftUI

struct CookleStartupView: View {
    let failureMessage: String?
    let openWithoutICloud: (() -> Void)?
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
                    if let openWithoutICloud {
                        Button("Open Without iCloud", action: openWithoutICloud)
                    }
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
        openWithoutICloud: (() -> Void)? = nil,
        retry: @escaping () -> Void = {
            // Intentionally empty for previews and isolated presentation.
        }
    ) {
        self.failureMessage = failureMessage
        self.openWithoutICloud = openWithoutICloud
        self.retry = retry
    }
}
