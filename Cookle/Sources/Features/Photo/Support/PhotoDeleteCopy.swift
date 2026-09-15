import CookleLibrary
import Foundation

enum PhotoDeleteCopy {
    static func title(for _: Photo) -> String {
        String(localized: "Delete Photo")
    }

    static func message(for photo: Photo) -> String {
        let affectedRowCount = (photo.objects ?? []).count
        if affectedRowCount == 0 {
            return String(localized: "This permanently deletes the photo. No recipes will be changed.")
        }

        return String(localized: """
        This deletes the photo from \(affectedRowCount) recipe entries. The recipes stay saved.
        """)
    }
}
