enum MainTab: CaseIterable {
    case diary
    case recipe
    case photo
    case settings
    case debug
    case search
}

extension MainTab: Identifiable {
    var id: String {
        .init(describing: self)
    }
}

extension MainTab {
    static func displayedTabs(
        isRegularWidth: Bool,
        isDebugOn: Bool
    ) -> [MainTab] {
        var tabs: [MainTab] = [
            .diary,
            .recipe,
            .photo,
            .settings,
            .search
        ]

        if isRegularWidth, isDebugOn {
            tabs.append(.debug)
        }

        return tabs
    }
}
