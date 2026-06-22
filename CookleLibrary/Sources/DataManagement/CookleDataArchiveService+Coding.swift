import Foundation
import SwiftData

extension CookleDataArchiveService {
    enum Identifier {
        static let firstIndexOffset = 1
    }

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]
        return encoder
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func identifierMap<Model: PersistentModel>(
        for models: [Model],
        prefix: String
    ) -> [PersistentIdentifier: String] {
        .init(
            uniqueKeysWithValues: models.enumerated().map { index, model in
                (
                    model.persistentModelID,
                    "\(prefix)-\(index + Identifier.firstIndexOffset)"
                )
            }
        )
    }

    static func identifier<Model: PersistentModel>(
        for model: Model,
        in identifiers: [PersistentIdentifier: String]
    ) -> String? {
        identifiers[model.persistentModelID]
    }
}
