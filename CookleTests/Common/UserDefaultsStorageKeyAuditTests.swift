import CookleLibrary
import Foundation
import Testing

@testable import Cookle

struct UserDefaultsStorageKeyAuditTests {
    @Test
    func appOwnedStorageKeys_areOpaqueUniqueAndCataloged() {
        let storageKeys = CookleKnownStorageDescriptors.all.map(\.storageKey)
        let catalogKeys = CookleUserDefaultsKeys.allStorageKeys

        #expect(storageKeys.isEmpty == false)
        #expect(Set(storageKeys).count == storageKeys.count)
        #expect(Set(storageKeys) == Set(catalogKeys))

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
