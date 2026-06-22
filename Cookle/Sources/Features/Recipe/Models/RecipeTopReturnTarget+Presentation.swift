import SwiftUI

extension RecipeTopReturnTarget {
    var title: Text {
        switch kind {
        case .activeCookingSession:
            Text("Resume Cooking")
        case .lastOpenedRecipe:
            Text("Back to Last Opened")
        }
    }

    var iconSystemName: String {
        switch kind {
        case .activeCookingSession:
            "fork.knife.circle"
        case .lastOpenedRecipe:
            "arrow.uturn.backward.circle"
        }
    }
}
