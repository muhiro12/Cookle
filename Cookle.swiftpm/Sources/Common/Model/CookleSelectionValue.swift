//
//  CookleSelectionValue.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/13/24.
//

import SwiftUI

enum CookleSelectionValue: Hashable {
    case mainNavigationSidebar(MainNavigationSidebar)
    case diary(Diary)
    case recipe(Recipe)
    case ingredient(Ingredient)
    case category(Category)
    case photo(Photo)
}

extension NavigationLink where Destination == Never {
    init(selection: CookleSelectionValue, @ViewBuilder label: () -> Label) {
        self.init(value: selection, label: label)
    }
}
