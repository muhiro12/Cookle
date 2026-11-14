import SwiftData

extension ModelContainer {
    var isICloudSyncEnabled: Bool {
        configurations.contains { configuration in
            configuration.cloudKitContainerIdentifier != nil
        }
    }
}
