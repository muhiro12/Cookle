enum MainTab: CaseIterable {
    case diary
    case recipe
    case photo
    case search
    case aiRecipe
}

extension MainTab: Identifiable {
    var id: String {
        .init(describing: self)
    }
}

extension MainTab {
    static func displayedTabs(includesAI: Bool) -> [MainTab] {
        [
            .diary,
            .recipe,
            .photo,
            .search
        ] + (includesAI ? [.aiRecipe] : [])
    }
}
