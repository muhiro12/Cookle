import CookleLibrary

enum PhotoDeleteCopy {
    static func title(for _: Photo) -> String {
        "Delete Photo"
    }

    static func message(for photo: Photo) -> String {
        let affectedRowCount = photo.objects.orEmpty.count
        let rowLabel = affectedRowCount == 1 ? "recipe photo row" : "recipe photo rows"

        if affectedRowCount == 0 {
            return "This removes the stored photo asset. No recipe photo rows will be removed."
        }

        return "This removes the stored photo asset and \(affectedRowCount) linked " +
            "\(rowLabel). Recipes stay saved."
    }

    static func successDialog(for _: Photo) -> String {
        "Deleted photo"
    }
}
