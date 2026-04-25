@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct PhotoPredicateTests {
    let context: ModelContext = makeTestContext()

    @Test
    func idIs_resolves_photo_by_persistent_identifier() throws {
        let targetPhoto = Photo.create(
            context: context,
            photoData: .init(
                data: Data("target-photo".utf8),
                source: .photosPicker
            )
        )
        _ = Photo.create(
            context: context,
            photoData: .init(
                data: Data("other-photo".utf8),
                source: .imagePlayground
            )
        )

        let photos = try context.fetch(
            .photos(.idIs(targetPhoto.persistentModelID))
        )

        #expect(photos.map(\.data) == [Data("target-photo".utf8)])
    }
}
