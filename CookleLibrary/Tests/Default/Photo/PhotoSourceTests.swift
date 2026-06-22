@testable import CookleLibrary
import Testing

@Suite("PhotoSource")
struct PhotoSourceTests {
    @Test("Provides the Photos picker as the default value")
    func defaultValue() {
        #expect(PhotoSource.defaultValue == .photosPicker)
    }

    @Test("Provides readable descriptions for each source")
    func descriptions() {
        #expect(PhotoSource.photosPicker.description == "Photos")
        #expect(PhotoSource.imagePlayground.description == "Image Playground")
    }
}
