import SwiftUI

extension DiaryTopSuggestion {
    var actionTitle: Text {
        switch mealType {
        case .breakfast:
            Text("Add \(recipeName) to today's breakfast")
        case .lunch:
            Text("Add \(recipeName) to today's lunch")
        case .dinner:
            Text("Add \(recipeName) to today's dinner")
        }
    }

    var detailText: Text {
        Text("Open an editable diary draft from your last opened recipe.")
    }
}
