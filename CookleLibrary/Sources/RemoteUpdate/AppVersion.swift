import Foundation

/// A one-to-three-component numeric version used for Cookle release policy.
public struct AppVersion: Comparable, Hashable, Sendable {
    private enum Format {
        static let minimumComponentCount = 1
        static let maximumComponentCount = 3
        static let normalizedComponentCount = 3
        static let majorIndex = 0
        static let minorIndex = 1
        static let patchIndex = 2
        static let zeroComponent = 0
        static let asciiZero: UInt32 = 48
        static let asciiNine: UInt32 = 57
    }

    private let major: Int
    private let minor: Int
    private let patch: Int

    /// Creates a version from one to three ASCII integer components.
    public init?(_ value: String) {
        let componentStrings = value.split(
            separator: ".",
            omittingEmptySubsequences: false
        )
        guard (
            Format.minimumComponentCount ... Format.maximumComponentCount
        ).contains(componentStrings.count) else {
            return nil
        }

        var components: [Int] = []
        for componentString in componentStrings {
            guard componentString.isEmpty == false,
                  componentString.unicodeScalars.allSatisfy({ scalar in
                    (Format.asciiZero ... Format.asciiNine).contains(scalar.value)
                  }),
                  let component = Int(componentString) else {
                return nil
            }
            components.append(component)
        }

        while components.count < Format.normalizedComponentCount {
            components.append(Format.zeroComponent)
        }

        major = components[Format.majorIndex]
        minor = components[Format.minorIndex]
        patch = components[Format.patchIndex]
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}
