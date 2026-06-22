@testable import CookleLibrary
import Foundation
import MHPlatformCore
import Testing

@Suite(.serialized)
struct CooklePreferencesTests {
    @Test("Stores and retrieves boolean preferences")
    func boolRoundTrip() {
        let descriptor = MHPreferenceDescriptors().isDebugOn
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: descriptor.storageKey)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: descriptor.storageKey)
            } else {
                defaults.removeObject(forKey: descriptor.storageKey)
            }
        }

        CooklePreferences.set(true, for: \.isDebugOn)
        #expect(CooklePreferences.bool(for: \.isDebugOn))

        CooklePreferences.set(false, for: \.isDebugOn)
        #expect(!CooklePreferences.bool(for: \.isDebugOn))
    }

    @Test("Stores and retrieves string preferences")
    func stringRoundTrip() {
        let descriptor = MHPreferenceDescriptors().lastLaunchedAppVersion
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: descriptor.storageKey)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: descriptor.storageKey)
            } else {
                defaults.removeObject(forKey: descriptor.storageKey)
            }
        }

        CooklePreferences.set(nil, for: \.lastLaunchedAppVersion)
        #expect(CooklePreferences.string(for: \.lastLaunchedAppVersion) == nil)

        let identifier = "recipe-identifier"
        CooklePreferences.set(identifier, for: \.lastLaunchedAppVersion)
        #expect(CooklePreferences.string(for: \.lastLaunchedAppVersion) == identifier)

        CooklePreferences.set(nil, for: \.lastLaunchedAppVersion)
        #expect(CooklePreferences.string(for: \.lastLaunchedAppVersion) == nil)
    }

    @Test("Stores and retrieves integer preferences")
    func intRoundTrip() {
        let descriptor = MHPreferenceDescriptors().dailyRecipeSuggestionHour
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: descriptor.storageKey)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: descriptor.storageKey)
            } else {
                defaults.removeObject(forKey: descriptor.storageKey)
            }
        }

        CooklePreferences.set(19, for: \.dailyRecipeSuggestionHour)
        #expect(CooklePreferences.int(for: \.dailyRecipeSuggestionHour) == 19)

        CooklePreferences.set(7, for: \.dailyRecipeSuggestionHour)
        #expect(CooklePreferences.int(for: \.dailyRecipeSuggestionHour) == 7)
    }

    @Test("Returns default integer value when preference is not set")
    func intDefaultValue() {
        let descriptor = MHPreferenceDescriptors().dailyRecipeSuggestionMinute
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: descriptor.storageKey)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: descriptor.storageKey)
            } else {
                defaults.removeObject(forKey: descriptor.storageKey)
            }
        }

        defaults.removeObject(forKey: descriptor.storageKey)
        #expect(CooklePreferences.int(for: \.dailyRecipeSuggestionMinute, default: 30) == 30)

        CooklePreferences.set(15, for: \.dailyRecipeSuggestionMinute)
        #expect(CooklePreferences.int(for: \.dailyRecipeSuggestionMinute, default: 30) == 15)
    }

    @Test("Tracks whether integer preferences are explicitly stored")
    func intContainsValue() {
        let descriptor = MHPreferenceDescriptors().dailyRecipeSuggestionHour
        let defaults = UserDefaults.standard
        let originalValue = defaults.object(forKey: descriptor.storageKey)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: descriptor.storageKey)
            } else {
                defaults.removeObject(forKey: descriptor.storageKey)
            }
        }

        defaults.removeObject(forKey: descriptor.storageKey)
        #expect(CooklePreferences.contains(\.dailyRecipeSuggestionHour) == false)

        CooklePreferences.set(18, for: \.dailyRecipeSuggestionHour)
        #expect(CooklePreferences.contains(\.dailyRecipeSuggestionHour))
    }
}
