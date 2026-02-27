enum MainTab: CaseIterable {
    case diary
    case recipe
    case photo
    case ingredient
    case category
    case settings
    case menu
    case debug
    case search
}

extension MainTab: Identifiable {
    var id: String {
        .init(describing: self)
    }
}
