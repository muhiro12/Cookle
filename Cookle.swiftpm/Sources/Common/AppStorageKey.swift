import SwiftUI

enum AppStorageKey: String {
    case isICloudOn = "AO9Yo1cC"
    case isDebugOn = "hd3fAy3G"
}

extension AppStorage<Bool> {
    init(_ key: AppStorageKey) {
        self.init(wrappedValue: false, key.rawValue)
    }
}
