import SwiftData
import SwiftUI

enum BoolAppStorageKey: String {
    case isSubscribeOn = "qWeRty12"
    case isICloudOn = "AO9Yo1cC"
    case isDebugOn = "hd3fAy3G"
}

enum PersistentIdentifierAppStorageKey: String {
    case lastOpenedRecipeID = "zxcXvb12"
}

extension AppStorage {
    init(_ key: BoolAppStorageKey) where Value == Bool {
        self.init(wrappedValue: false, key.rawValue)
    }

    init(_ key: PersistentIdentifierAppStorageKey) where Value == PersistentIdentifier? {
        self.init(key.rawValue)
    }
}
