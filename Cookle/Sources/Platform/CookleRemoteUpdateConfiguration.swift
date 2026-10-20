import CookleLibrary
import Foundation
import MHPlatform

@MainActor
enum CookleRemoteUpdateConfiguration {
    private static let appStoreIdentifier = 6_483_363_226

    static func makeOperations(isIsolated: Bool, logger: MHLogger) -> RemoteUpdateOperations {
        guard isIsolated == false,
              Bundle.main.bundleIdentifier?.contains("playgrounds") == false,
              ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            return .init()
        }
        do {
            guard let configurationURL = URL(
                string: "https://raw.githubusercontent.com/muhiro12/MHAppConfig/main/cookle/app.json"
            ) else {
                throw URLError(.badURL)
            }
            let controller = try MHRemoteUpdateController(
                appStoreID: appStoreIdentifier,
                configurationURL: configurationURL,
                storefront: "jp"
            )
            return .init(controller: controller)
        } catch {
            logger.error(
                "remote update configuration failed",
                metadata: ["errorType": String(reflecting: type(of: error))]
            )
            return .init()
        }
    }
}
