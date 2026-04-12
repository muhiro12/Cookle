import CookleLibrary
import Foundation
import MHPreferences
import SwiftUI
import Testing

@testable import Cookle

@MainActor
@Suite(.serialized)
struct AppStorageCookleSharedStoreTests {
    private struct BoolHarness {
        @AppStorage private var value: Bool

        var wrappedValue: Bool {
            get {
                value
            }
            set {
                value = newValue
            }
        }

        init(
            key: BoolPreferenceKey,
            store: UserDefaults? = nil
        ) {
            if let store {
                _value = AppStorage(
                    key,
                    store: store
                )
            } else {
                _value = AppStorage(key)
            }
        }
    }

    private struct IntHarness {
        @AppStorage private var value: Int

        var wrappedValue: Int {
            get {
                value
            }
            set {
                value = newValue
            }
        }

        init(
            key: IntPreferenceKey,
            store: UserDefaults? = nil
        ) {
            if let store {
                _value = AppStorage(
                    key,
                    store: store
                )
            } else {
                _value = AppStorage(key)
            }
        }
    }

    private struct StringHarness {
        @AppStorage private var value: String

        var wrappedValue: String {
            get {
                value
            }
            set {
                value = newValue
            }
        }

        init(
            key: StringPreferenceKey,
            store: UserDefaults? = nil
        ) {
            if let store {
                _value = AppStorage(
                    key,
                    store: store
                )
            } else {
                _value = AppStorage(key)
            }
        }
    }

    @Test
    func boolAdapterUsesTypedKeyDefault() {
        let key = BoolPreferenceKey.isDebugOn
        let userDefaults = makeTestUserDefaults()
        var harness = BoolHarness(
            key: key,
            store: userDefaults
        )

        #expect(harness.wrappedValue == false)

        harness.wrappedValue = true
        #expect(userDefaults.bool(forKey: key.rawValue))
    }

    @Test
    func intAdapterUsesTypedKeyDefault() {
        let key = IntPreferenceKey.dailyRecipeSuggestionHour
        let userDefaults = makeTestUserDefaults()
        var harness = IntHarness(
            key: key,
            store: userDefaults
        )

        #expect(harness.wrappedValue == .zero)

        harness.wrappedValue = 19
        #expect(userDefaults.integer(forKey: key.rawValue) == 19)
    }

    @Test
    func requiredStringAdapterUsesEmptyDefaultAndRoundTrip() {
        let key = StringPreferenceKey.lastLaunchedAppVersion
        let userDefaults = makeTestUserDefaults()
        var harness = StringHarness(
            key: key,
            store: userDefaults
        )

        #expect(harness.wrappedValue.isEmpty)

        harness.wrappedValue = "3.3"
        #expect(userDefaults.string(forKey: key.rawValue) == "3.3")
    }

    @Test
    func defaultStoreUsesSharedUserDefaults() {
        let key = StringPreferenceKey.lastOpenedRecipeID
        let sharedDefaults = makeSharedUserDefaults()
        let originalValue = sharedDefaults.object(forKey: key.rawValue)
        defer {
            restoreValue(
                originalValue,
                forKey: key.rawValue,
                in: sharedDefaults
            )
        }

        sharedDefaults.removeObject(forKey: key.rawValue)

        var harness = StringHarness(key: key)
        #expect(harness.wrappedValue.isEmpty)

        harness.wrappedValue = "3.3"
        #expect(sharedDefaults.string(forKey: key.rawValue) == "3.3")
    }

    @Test
    func defaultStoreUsesStandardUserDefaults() {
        let key = StringPreferenceKey.lastLaunchedAppVersion
        let standardDefaults = UserDefaults.standard
        let originalValue = standardDefaults.object(forKey: key.rawValue)
        defer {
            restoreValue(
                originalValue,
                forKey: key.rawValue,
                in: standardDefaults
            )
        }

        standardDefaults.removeObject(forKey: key.rawValue)

        var harness = StringHarness(key: key)
        #expect(harness.wrappedValue.isEmpty)

        harness.wrappedValue = "3.3"
        #expect(standardDefaults.string(forKey: key.rawValue) == "3.3")
    }

    @Test
    func injectedStoreOverridesDescriptorDefaultSelection() {
        let key = StringPreferenceKey.lastOpenedRecipeID
        let sharedDefaults = makeSharedUserDefaults()
        let originalValue = sharedDefaults.object(forKey: key.rawValue)
        defer {
            restoreValue(
                originalValue,
                forKey: key.rawValue,
                in: sharedDefaults
            )
        }

        sharedDefaults.set("shared-value", forKey: key.rawValue)
        let localDefaults = makeTestUserDefaults()
        var harness = StringHarness(
            key: key,
            store: localDefaults
        )

        harness.wrappedValue = "local-value"

        #expect(localDefaults.string(forKey: key.rawValue) == "local-value")
        #expect(sharedDefaults.string(forKey: key.rawValue) == "shared-value")
    }
}

private extension AppStorageCookleSharedStoreTests {
    func makeSharedUserDefaults() -> UserDefaults {
        UserDefaults(
            suiteName: UserDefaults.appGroupIdentifier
        ) ?? .standard
    }

    func restoreValue(
        _ value: Any?,
        forKey key: String,
        in userDefaults: UserDefaults
    ) {
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}
