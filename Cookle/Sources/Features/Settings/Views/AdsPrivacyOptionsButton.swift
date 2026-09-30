import MHPlatform
import SwiftUI

/// Reopens the consent SDK's privacy options when the runtime requires an entry point.
struct AdsPrivacyOptionsButton: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    @State private var isPresentingPrivacyOptions = false

    let onError: (String) -> Void

    var body: some View {
        if appRuntime.adsPrivacyOptionsRequirement == .required {
            Button("Privacy Options") {
                presentPrivacyOptions()
            }
            .disabled(isPresentingPrivacyOptions)
        }
    }
}

private extension AdsPrivacyOptionsButton {
    func presentPrivacyOptions() {
        guard isPresentingPrivacyOptions == false else {
            return
        }
        isPresentingPrivacyOptions = true

        Task {
            defer {
                isPresentingPrivacyOptions = false
            }
            do {
                try await appRuntime.presentAdsPrivacyOptions()
            } catch {
                onError(error.localizedDescription)
            }
        }
    }
}
