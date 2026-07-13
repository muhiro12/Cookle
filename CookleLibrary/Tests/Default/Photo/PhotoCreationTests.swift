@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct PhotoCreationTests {
    let context: ModelContext = makeTestContext()

    @Test
    func create_reusesExistingBinaryData() throws {
        let photoData = PhotoData(
            data: Data("shared-photo".utf8),
            source: .photosPicker
        )

        let firstPhoto = try Photo.create(
            context: context,
            photoData: photoData
        )
        let secondPhoto = try Photo.create(
            context: context,
            photoData: photoData
        )

        #expect(firstPhoto.persistentModelID == secondPhoto.persistentModelID)
        #expect(try context.fetchCount(FetchDescriptor<Photo>()) == 1)
    }
}
