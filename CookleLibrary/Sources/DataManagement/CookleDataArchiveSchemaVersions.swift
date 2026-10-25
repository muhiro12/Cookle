import SwiftData

/// SwiftData schema versions an export file can declare.
///
/// An export's records follow the schema that wrote them, so the file's
/// `schemaVersion` is the persistent schema's version identifier. Supported
/// exported versions retain historical value readers and semantic adapters;
/// file decoding does not need to execute the store migration plan. Readability
/// also requires a supported format version, as recorded in the format overview.
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

    /// Exported schema versions this build reads, oldest first.
    /// Store-only schema history does not itself register a file reader.
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
