import SwiftData

/// SwiftData schema versions an export file can declare.
///
/// An export's records follow the schema that wrote them, so the file's
/// `schemaVersion` is the persistent schema's version identifier. Every schema
/// in `CookleMigrationPlan.schemas` must stay readable; a later schema adds a
/// reader that upgrades its files through the migration plan.
enum CookleDataArchiveSchemaVersions {
    private enum Component {
        static let separator: Character = "."
        static let count = 3
        static let major = 0
        static let minor = 1
        static let patch = 2
    }

    /// Version written by this build.
    static var current: Schema.Version {
        CookleMigrationPlan.currentSchema.versionIdentifier
    }

    /// Versions whose records this build reads, oldest first.
    static var readable: [Schema.Version] {
        [
            CookleSchemaV1.versionIdentifier
        ]
    }

    static func string(
        for version: Schema.Version
    ) -> String {
        [
            version.major,
            version.minor,
            version.patch
        ]
        .map(String.init)
        .joined(separator: String(Component.separator))
    }

    static func version(
        from string: String
    ) -> Schema.Version? {
        let components = string.split(
            separator: Component.separator,
            omittingEmptySubsequences: false
        )
        guard components.count == Component.count else {
            return nil
        }

        var numbers = [Int]()
        for component in components {
            guard component.isEmpty == false,
                  component.allSatisfy({ character in
                    character.isASCII && character.isNumber
                  }),
                  let number = Int(component) else {
                return nil
            }
            numbers.append(number)
        }
        return .init(
            numbers[Component.major],
            numbers[Component.minor],
            numbers[Component.patch]
        )
    }
}
