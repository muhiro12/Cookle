import Foundation
import SwiftData

extension CookleDataArchiveService {
    enum Identifier {
        static let firstIndexOffset = 1
    }

    static var encoder: JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]
        return jsonEncoder
    }

    static var decoder: JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        return jsonDecoder
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
