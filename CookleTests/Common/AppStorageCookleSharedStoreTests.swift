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
            keyPath: KeyPath<MHPreferenceDescriptors, MHBoolPreferenceDescriptor>,
            store: UserDefaults? = nil
        ) {
            if let store {
                _value = AppStorage(
                    keyPath,
                    store: store
                )
            } else {
                _value = AppStorage(keyPath)
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
            keyPath: KeyPath<MHPreferenceDescriptors, MHIntPreferenceDescriptor>,
            store: UserDefaults? = nil
        ) {
            if let store {
                _value = AppStorage(
                    keyPath,
                    store: store
                )
            } else {
                _value = AppStorage(keyPath)
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
            keyPath: KeyPath<MHPreferenceDescriptors, MHStringPreferenceDescriptor>,
            store: UserDefaults? = nil
        ) {
            if let store {
                _value = AppStorage(
                    keyPath,
                    default: "",
                    store: store
                )
            } else {
                _value = AppStorage(
                    keyPath,
                    default: ""
                )
            }
        }
    }

    @Test
    func boolAdapterUsesTypedKeyDefault() {
        let descriptor = MHPreferenceDescriptors().isDebugOn
        let userDefaults = makeTestUserDefaults()
        var harness = BoolHarness(
            keyPath: \.isDebugOn,
            store: userDefaults
        )

        #expect(harness.wrappedValue == false)

        harness.wrappedValue = true
        #expect(userDefaults.bool(forKey: descriptor.storageKey))
    }

    @Test
    func intAdapterUsesTypedKeyDefault() {
        let descriptor = MHPreferenceDescriptors().dailyRecipeSuggestionHour
        let userDefaults = makeTestUserDefaults()
        var harness = IntHarness(
            keyPath: \.dailyRecipeSuggestionHour,
            store: userDefaults
        )

        #expect(harness.wrappedValue == .zero)

        harness.wrappedValue = 19
        #expect(userDefaults.integer(forKey: descriptor.storageKey) == 19)
    }

    @Test
    func requiredStringAdapterUsesEmptyDefaultAndRoundTrip() {
        let descriptor = MHPreferenceDescriptors().lastLaunchedAppVersion
        let userDefaults = makeTestUserDefaults()
        var harness = StringHarness(
            keyPath: \.lastLaunchedAppVersion,
            store: userDefaults
        )

        #expect(harness.wrappedValue.isEmpty)

        harness.wrappedValue = "3.3"
        #expect(userDefaults.string(forKey: descriptor.storageKey) == "3.3")
    }

    @Test
    func defaultStoreUsesSharedUserDefaults() {
        let descriptor = MHPreferenceDescriptors().lastOpenedRecipeID
        let sharedDefaults = makeSharedUserDefaults()
        let originalValue = sharedDefaults.object(forKey: descriptor.storageKey)
        defer {
            restoreValue(
                originalValue,
                forKey: descriptor.storageKey,
                in: sharedDefaults
            )
        }

        sharedDefaults.removeObject(forKey: descriptor.storageKey)

        var harness = StringHarness(keyPath: \.lastOpenedRecipeID)
        #expect(harness.wrappedValue.isEmpty)

        harness.wrappedValue = "3.3"
        #expect(sharedDefaults.string(forKey: descriptor.storageKey) == "3.3")
    }

    @Test
    func defaultStoreUsesStandardUserDefaults() {
        let descriptor = MHPreferenceDescriptors().lastLaunchedAppVersion
        let standardDefaults = UserDefaults.standard
        let originalValue = standardDefaults.object(forKey: descriptor.storageKey)
        defer {
            restoreValue(
                originalValue,
                forKey: descriptor.storageKey,
                in: standardDefaults
            )
        }

        standardDefaults.removeObject(forKey: descriptor.storageKey)

        var harness = StringHarness(keyPath: \.lastLaunchedAppVersion)
        #expect(harness.wrappedValue.isEmpty)

        harness.wrappedValue = "3.3"
        #expect(standardDefaults.string(forKey: descriptor.storageKey) == "3.3")
    }

    @Test
    func injectedStoreOverridesDescriptorDefaultSelection() {
        let descriptor = MHPreferenceDescriptors().lastOpenedRecipeID
        let sharedDefaults = makeSharedUserDefaults()
        let originalValue = sharedDefaults.object(forKey: descriptor.storageKey)
        defer {
            restoreValue(
                originalValue,
                forKey: descriptor.storageKey,
                in: sharedDefaults
            )
        }

        sharedDefaults.set("shared-value", forKey: descriptor.storageKey)
        let localDefaults = makeTestUserDefaults()
        var harness = StringHarness(
            keyPath: \.lastOpenedRecipeID,
            store: localDefaults
        )

        harness.wrappedValue = "local-value"

        #expect(localDefaults.string(forKey: descriptor.storageKey) == "local-value")
        #expect(sharedDefaults.string(forKey: descriptor.storageKey) == "shared-value")
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
