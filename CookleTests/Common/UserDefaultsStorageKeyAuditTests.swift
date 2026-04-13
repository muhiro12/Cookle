import CookleLibrary
import Foundation
import Testing

@testable import Cookle

struct UserDefaultsStorageKeyAuditTests {
    @Test
    func appOwnedStorageKeys_areOpaqueAndUnique() {
        let storageKeys = CookleKnownStorageDescriptors.all.map(\.storageKey)

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
