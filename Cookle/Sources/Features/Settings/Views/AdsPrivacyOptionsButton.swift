import MHPlatform
import SwiftUI

/// Reopens the consent SDK's privacy options when the runtime requires an entry point.
struct AdsPrivacyOptionsButton: View {
    @Environment(MHAppRuntime.self)
    private var appRuntime

    let onError: (String) -> Void

    var body: some View {
        if appRuntime.adsPrivacyOptionsRequirement == .required {
            Button("Privacy Options") {
                Task {
                    do {
                        try await appRuntime.presentAdsPrivacyOptions()
                    } catch {
                        onError(error.localizedDescription)
                    }
                }
            }
        }
    }
}
