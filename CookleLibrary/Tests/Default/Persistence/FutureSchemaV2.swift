@testable import CookleLibrary
import Foundation
import SwiftData

/// A schema Cookle has never released, standing in for a future version.
///
/// Declared at file scope because a `@Model` class cannot sit two levels deep
/// inside the test type.
enum FutureSchemaV2: VersionedSchema {
    enum Value {
        static let majorVersion = 2
    }

    @Model
    final class FutureNote {
        var body = ""

        init() {
            // Fixture values are assigned before saving.
        }
    }

    static var versionIdentifier: Schema.Version {
        .init(Value.majorVersion, .zero, .zero)
    }

    static var models: [any PersistentModel.Type] {
        CookleSchemaV1.models + [FutureNote.self]
    }
}
