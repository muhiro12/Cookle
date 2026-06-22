import CookleLibrary
import Foundation

enum PhotoDisplayCopy {
    static func title(for photo: Photo) -> String {
        photo.linkedRecipeNames ?? String(localized: "Unlinked Photo")
    }
}
