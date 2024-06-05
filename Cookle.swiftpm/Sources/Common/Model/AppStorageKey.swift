import SwiftUI

enum AppStorageKey: String {
    case isSubscribeOn = "qWeRty12"
    case isICloudOn = "AO9Yo1cC"
    case isDebugOn = "hd3fAy3G"
}

extension AppStorage<Bool> {
    init(_ key: AppStorageKey) {
        self.init(wrappedValue: false, key.rawValue)
    }
}
