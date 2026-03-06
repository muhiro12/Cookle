import MHPlatform
import SwiftUI

extension AppStorage {
    init(_ key: StringPreferenceKey) where Value == String? {
        self.init(key.preferenceKey)
    }

    init(_ key: BoolPreferenceKey) where Value == Bool {
        self.init(key.preferenceKey)
    }

    init(_ key: IntPreferenceKey) where Value == Int {
        self.init(
            key.preferenceKey(default: .zero)
        )
    }
}
