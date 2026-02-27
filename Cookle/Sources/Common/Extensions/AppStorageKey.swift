import SwiftUI

extension AppStorage {
    init(_ key: StringPreferenceKey) where Value == String? {
        self.init(key.rawValue)
    }

    init(_ key: BoolPreferenceKey) where Value == Bool {
        self.init(wrappedValue: false, key.rawValue)
    }

    init(_ key: IntPreferenceKey) where Value == Int {
        self.init(wrappedValue: .zero, key.rawValue)
    }
}
