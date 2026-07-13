import Darwin
import Foundation

private enum RemoteUpdateConfigurationValidator {
    private enum ValidationError: LocalizedError {
        case invalid(String)

        var errorDescription: String? {
            switch self {
            case .invalid(let message):
                message
            }
        }
    }

    private struct Configuration: Decodable {
        let forceUpdate: ForceUpdate?
    }

    private struct ForceUpdate: Decodable {
        let minimumVersion: String
        let activatedAt: Date
        let expiresAt: Date
    }

    private static let expectedArgumentCount = 2
    private static let configurationPathIndex = 1
    private static let maximumActivationHours = 72
    private static let minutesPerHour = 60
    private static let secondsPerMinute = 60
    private static let minimumVersionComponentCount = 1
    private static let maximumVersionComponentCount = 3
    private static let asciiZero: UInt32 = 48
    private static let asciiNine: UInt32 = 57

    private static var maximumActivationDuration: TimeInterval {
        TimeInterval(
            maximumActivationHours
                * minutesPerHour
                * secondsPerMinute
        )
    }

    static func run(arguments: [String]) {
        do {
            guard arguments.count == expectedArgumentCount else {
                throw ValidationError.invalid(
                    "Usage: RemoteUpdateConfigurationValidator.swift <configuration-path>"
                )
            }

            let path = arguments[configurationPathIndex]
            let data = try Data(
                contentsOf: URL(fileURLWithPath: path)
            )
            try validate(data: data)
            print("Remote update configuration is valid.")
        } catch {
            FileHandle.standardError.write(
                Data(
                    "Remote update configuration is invalid: \(error.localizedDescription)\n".utf8
                )
            )
            exit(EXIT_FAILURE)
        }
    }

    private static func validate(data: Data) throws {
        let json = try JSONSerialization.jsonObject(
            with: data,
            options: []
        )
        guard let root = json as? [String: Any],
              Set(root.keys) == ["forceUpdate"] else {
            throw ValidationError.invalid(
                "The root object must contain only the forceUpdate key."
            )
        }

        if root["forceUpdate"] is NSNull {
            return
        }

        guard let policy = root["forceUpdate"] as? [String: Any],
              Set(policy.keys) == [
                "minimumVersion",
                "activatedAt",
                "expiresAt"
              ],
              policy["minimumVersion"] is String,
              policy["activatedAt"] is String,
              policy["expiresAt"] is String else {
            throw ValidationError.invalid(
                "forceUpdate must be null or a complete policy object."
            )
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let configuration = try decoder.decode(
            Configuration.self,
            from: data
        )
        guard let forceUpdate = configuration.forceUpdate,
              isValidVersion(forceUpdate.minimumVersion) else {
            throw ValidationError.invalid(
                "minimumVersion must contain one to three ASCII integer components."
            )
        }

        let duration = forceUpdate.expiresAt.timeIntervalSince(
            forceUpdate.activatedAt
        )
        guard duration.isFinite,
              duration > 0,
              duration <= maximumActivationDuration else {
            throw ValidationError.invalid(
                "The force-update window must be longer than zero and at most 72 hours."
            )
        }
    }

    private static func isValidVersion(
        _ value: String
    ) -> Bool {
        let components = value.split(
            separator: ".",
            omittingEmptySubsequences: false
        )
        guard (
            minimumVersionComponentCount ... maximumVersionComponentCount
        ).contains(components.count) else {
            return false
        }

        return components.allSatisfy { component in
            component.isEmpty == false
                && component.unicodeScalars.allSatisfy { scalar in
                    (asciiZero ... asciiNine).contains(scalar.value)
                }
                && Int(component) != nil
        }
    }
}

RemoteUpdateConfigurationValidator.run(
    arguments: ProcessInfo.processInfo.arguments
)
