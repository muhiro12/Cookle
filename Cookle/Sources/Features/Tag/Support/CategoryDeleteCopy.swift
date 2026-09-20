import CookleLibrary
import Foundation

enum CategoryDeleteCopy {
    static func title(for category: Category) -> String {
        String(localized: "Delete \(category.value)")
    }

    static func confirmationDialog(for category: Category) -> String {
        "\(title(for: category))? \(message(for: category))"
    }

    static func message(for category: Category) -> String {
        let affectedRecipeCount = (category.recipes ?? []).count

        if affectedRecipeCount == 0 {
            return String(
                localized: "This removes the category. No recipe relations will be removed."
            )
        }

        if affectedRecipeCount == 1 {
            return String(
                localized: "This removes the category from one recipe. The recipe stays saved."
            )
        }

        return String(
            localized: """
            This removes the category from \(affectedRecipeCount) recipes. \
            The recipes stay saved.
            """
        )
    }

    static func successDialog(for category: Category) -> String {
        String(localized: "Deleted \(category.value)")
    }
}
