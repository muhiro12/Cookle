import Foundation
import SwiftData

/// Canonical codec for stable persistent model identifiers shared across targets.
public enum PersistentModelStableIdentifierCodec {
    /// Errors thrown while decoding stable persistent model identifiers.
    public enum Error: Swift.Error {
        case invalidBase64String
    }

    /// Encodes a persistent model identifier into a stable string.
    public static func encode(
        _ identifier: PersistentIdentifier
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(identifier).base64EncodedString()
    }

    /// Encodes a persistent model identifier into a stable string when possible.
    public static func encodeIfPossible(
        _ identifier: PersistentIdentifier
    ) -> String? {
        try? encode(identifier)
    }

    /// Returns a stable identifier for a persistent model, with a deterministic fallback.
    public static func stableIdentifier<Model: PersistentModel>(
        for model: Model
    ) -> String {
        if let encodedIdentifier = encodeIfPossible(model.persistentModelID) {
            return encodedIdentifier
        }
        return String(describing: model.persistentModelID)
    }

    /// Decodes a stable string into a persistent model identifier.
    public static func decode(
        _ stableIdentifier: String
    ) throws -> PersistentIdentifier {
        guard let data = Data(base64Encoded: stableIdentifier) else {
            throw Error.invalidBase64String
        }
        return try JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }
}
