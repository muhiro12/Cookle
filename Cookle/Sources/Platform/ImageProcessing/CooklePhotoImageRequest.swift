import Foundation
import SwiftData

nonisolated struct CooklePhotoImageRequest: Hashable, Sendable {
    nonisolated enum Identity: Hashable, Sendable {
        case stored(PersistentIdentifier)
        case draft(UUID)
    }

    nonisolated enum Size: Int, Hashable, Sendable {
        case thumbnail = 512
        case preview = 1_280
        case detail = 3_072
    }

    let identity: Identity
    let size: Size
}
