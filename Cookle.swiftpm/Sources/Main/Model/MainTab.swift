//
//  MainTab.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

enum MainTab {
    case diary
    case recipe
    case photo
    case ingredient
    case category
    case settings
    case debug
    case menu
    case search
}

extension MainTab: Identifiable {
    var id: String {
        .init(describing: self)
    }
}
