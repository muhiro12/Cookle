import Foundation
@testable import CookleLibrary
import Testing

@Suite("CooklePreferences")
struct CooklePreferencesTests {
    @Test("Stores and retrieves boolean preferences")
    func boolRoundTrip() {
        let key = BoolPreferenceKey.isDebugOn
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: key.rawValue)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: key.rawValue)
            } else {
                defaults.removeObject(forKey: key.rawValue)
            }
        }

        CooklePreferences.set(true, for: key)
        #expect(CooklePreferences.bool(for: key))

        CooklePreferences.set(false, for: key)
        #expect(!CooklePreferences.bool(for: key))
    }

    @Test("Stores and retrieves string preferences")
    func stringRoundTrip() {
        let key = StringPreferenceKey.lastOpenedRecipeID
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: key.rawValue)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: key.rawValue)
            } else {
                defaults.removeObject(forKey: key.rawValue)
            }
        }

        CooklePreferences.set(nil, for: key)
        #expect(CooklePreferences.string(for: key) == nil)

        let identifier = "recipe-identifier"
        CooklePreferences.set(identifier, for: key)
        #expect(CooklePreferences.string(for: key) == identifier)

        CooklePreferences.set(nil, for: key)
        #expect(CooklePreferences.string(for: key) == nil)
    }
}
