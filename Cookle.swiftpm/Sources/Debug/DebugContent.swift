import SwiftUI

enum DebugContent: Int {    
    case diary
    case diaryObject
    case recipe
    case ingredient
    case ingredientObject
    case category
}

extension DebugContent: CaseIterable {}

extension DebugContent: Identifiable {
    var id: Int {
        rawValue
    }
}
