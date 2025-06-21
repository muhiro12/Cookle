import SwiftUI

enum BoolAppStorageKey: String {
    case isSubscribeOn = "qWeRty12"
    case isICloudOn = "AO9Yo1cC"
    case isDebugOn = "hd3fAy3G"
}

enum StringAppStorageKey: String {
    case lastOpenedRecipeID = "zxcXvb12"
}

extension AppStorage {
    init(_ key: StringAppStorageKey) where Value == String? {
        self.init(key.rawValue)
    }

    init(_ key: BoolAppStorageKey) where Value == Bool {
        self.init(wrappedValue: false, key.rawValue)
    }
}
