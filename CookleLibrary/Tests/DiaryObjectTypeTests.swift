@testable import CookleLibrary
import Foundation
import Testing

@Suite("DiaryObjectType")
struct DiaryObjectTypeTests {
    @Test("Decodes legacy raw-value payload")
    func decodesLegacyRawValuePayload() throws {
        let decoder = JSONDecoder()
        let data = Data(#""breakfast""#.utf8)

        let value = try decoder.decode(DiaryObjectType.self, from: data)
        #expect(value == .breakfast)
    }

    @Test("Decodes keyed payload from non-raw enum encoding")
    func decodesKeyedPayload() throws {
        let decoder = JSONDecoder()
        let data = Data(#"{"lunch":{}}"#.utf8)

        let value = try decoder.decode(DiaryObjectType.self, from: data)
        #expect(value == .lunch)
    }

    @Test("Encodes to stable raw-value payload")
    func encodesToRawValuePayload() throws {
        let encoder = JSONEncoder()

        let data = try encoder.encode(DiaryObjectType.dinner)
        let json = String(decoding: data, as: UTF8.self)

        #expect(json == #""dinner""#)
    }
}
