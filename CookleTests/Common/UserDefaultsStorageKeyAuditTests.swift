import CookleLibrary
import Foundation
import Testing

@testable import Cookle

struct UserDefaultsStorageKeyAuditTests {
    @Test
    func appOwnedStorageKeys_areOpaqueAndUnique() {
        let storageKeys =
            BoolPreferenceKey.allCases.map(\.rawValue)
            + IntPreferenceKey.allCases.map(\.rawValue)
            + StringPreferenceKey.allCases.map(\.rawValue)
            + CodablePreferenceKey.allCases.map(\.rawValue)
            + CookleInternalPreferenceKey.allCases.map(\.rawValue)

        #expect(storageKeys.isEmpty == false)
        #expect(Set(storageKeys).count == storageKeys.count)

        for storageKey in storageKeys {
            #expect(
                storageKey.range(
                    of: "^[A-Za-z0-9]{8}$",
                    options: .regularExpression
                ) != nil
            )
        }
    }
}
