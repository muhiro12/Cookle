enum MainTab: CaseIterable {
    case diary
    case recipe
    case photo
    case settings
    case search
}

extension MainTab: Identifiable {
    var id: String {
        .init(describing: self)
    }
}

extension MainTab {
    static func displayedTabs() -> [MainTab] {
        [
            .diary,
            .recipe,
            .photo,
            .settings,
            .search
        ]
    }
}
