enum MainTab: CaseIterable {
    case diary
    case recipe
    case photo
    case search
}

extension MainTab: Identifiable {
    var id: String {
        .init(describing: self)
    }
}
