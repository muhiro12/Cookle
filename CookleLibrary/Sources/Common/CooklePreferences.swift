import Foundation

public enum BoolPreferenceKey: String {
    case isSubscribeOn = "qWeRty12"
    case isICloudOn = "AO9Yo1cC"
    case isDebugOn = "hd3fAy3G"
}

public enum StringPreferenceKey: String {
    case lastOpenedRecipeID = "zxcXvb12"
}

public enum CooklePreferences {
    private static var userDefaults: UserDefaults {
        .standard
    }

    public static func bool(for key: BoolPreferenceKey) -> Bool {
        userDefaults.bool(forKey: key.rawValue)
    }

    public static func set(_ value: Bool, for key: BoolPreferenceKey) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    public static func string(for key: StringPreferenceKey) -> String? {
        userDefaults.string(forKey: key.rawValue)
    }

    public static func set(_ value: String?, for key: StringPreferenceKey) {
        if let value {
            userDefaults.set(value, forKey: key.rawValue)
        } else {
            userDefaults.removeObject(forKey: key.rawValue)
        }
    }
}
