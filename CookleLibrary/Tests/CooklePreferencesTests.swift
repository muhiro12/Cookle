@testable import CookleLibrary
import Foundation
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

    @Test("Stores and retrieves integer preferences")
    func intRoundTrip() {
        let key = IntPreferenceKey.dailyRecipeSuggestionHour
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: key.rawValue)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: key.rawValue)
            } else {
                defaults.removeObject(forKey: key.rawValue)
            }
        }

        CooklePreferences.set(19, for: key)
        #expect(CooklePreferences.int(for: key) == 19)

        CooklePreferences.set(7, for: key)
        #expect(CooklePreferences.int(for: key) == 7)
    }

    @Test("Returns default integer value when preference is not set")
    func intDefaultValue() {
        let key = IntPreferenceKey.dailyRecipeSuggestionMinute
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: key.rawValue)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: key.rawValue)
            } else {
                defaults.removeObject(forKey: key.rawValue)
            }
        }

        defaults.removeObject(forKey: key.rawValue)
        #expect(CooklePreferences.int(for: key, default: 30) == 30)

        CooklePreferences.set(15, for: key)
        #expect(CooklePreferences.int(for: key, default: 30) == 15)
    }
}
