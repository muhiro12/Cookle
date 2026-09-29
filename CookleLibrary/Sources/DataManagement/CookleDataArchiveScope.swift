/// Which part of a person's Cookle data an export file contains.
///
/// Only a complete library can replace current data. Any other scope, including
/// one this version of Cookle does not know yet, describes a referentially
/// complete subset that can only be merged.
public enum CookleDataArchiveScope: Hashable, Sendable {
    /// Every recipe, diary, tag, and photo, including records nothing references.
    case all
    /// A subset such as selected recipes, identified by its scope name.
    case partial(String)

    static let allRawValue = "all"

    /// The scope name written to the file.
    public var rawValue: String {
        switch self {
        case .all:
            Self.allRawValue
        case .partial(let name):
            name
        }
    }

    init(rawValue: String) {
        if rawValue == Self.allRawValue {
            self = .all
        } else {
            self = .partial(rawValue)
        }
    }
}
