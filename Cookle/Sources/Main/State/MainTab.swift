enum MainTab: CaseIterable {
    case diary
    case recipe
    case photo
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
