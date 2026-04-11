enum RecipeBrowseResults {
    struct Criteria {
        let searchText: String
        let selectedCategory: Category?
        let selectedIngredient: Ingredient?
        let photosOnly: Bool
        let sortMode: RecipeBrowseSortMode
        let isAscending: Bool
    }

    static func recipes(
        from recipes: [Recipe],
        criteria: Criteria
    ) -> [Recipe] {
        recipes
            .filter { recipe in
                matchesSearch(
                    recipe: recipe,
                    searchText: criteria.searchText
                )
            }
            .filter { recipe in
                matchesCategory(
                    recipe: recipe,
                    selectedCategory: criteria.selectedCategory
                )
            }
            .filter { recipe in
                matchesIngredient(
                    recipe: recipe,
                    selectedIngredient: criteria.selectedIngredient
                )
            }
            .filter { recipe in
                matchesPhotoRequirement(
                    recipe: recipe,
                    photosOnly: criteria.photosOnly
                )
            }
            .sorted { lhs, rhs in
                comesBefore(
                    lhs,
                    rhs,
                    sortMode: criteria.sortMode,
                    isAscending: criteria.isAscending
                )
            }
    }
}

private extension RecipeBrowseResults {
    static func matchesSearch(
        recipe: Recipe,
        searchText: String
    ) -> Bool {
        searchText.isEmpty || recipe.name.normalizedContains(searchText)
    }

    static func matchesCategory(
        recipe: Recipe,
        selectedCategory: Category?
    ) -> Bool {
        guard let selectedCategory else {
            return true
        }

        return recipe.categories.orEmpty.contains { category in
            category.persistentModelID == selectedCategory.persistentModelID
        }
    }

    static func matchesIngredient(
        recipe: Recipe,
        selectedIngredient: Ingredient?
    ) -> Bool {
        guard let selectedIngredient else {
            return true
        }

        return recipe.ingredients.orEmpty.contains { ingredient in
            ingredient.persistentModelID == selectedIngredient.persistentModelID
        }
    }

    static func matchesPhotoRequirement(
        recipe: Recipe,
        photosOnly: Bool
    ) -> Bool {
        photosOnly == false || recipe.photoObjects.orEmpty.isNotEmpty
    }

    static func comesBefore(
        _ lhs: Recipe,
        _ rhs: Recipe,
        sortMode: RecipeBrowseSortMode,
        isAscending: Bool
    ) -> Bool {
        switch sortMode {
        case .alphabetical:
            return compareNames(
                lhs.name,
                rhs.name,
                ascending: isAscending
            )
        case .recentlyCreated:
            if lhs.createdTimestamp != rhs.createdTimestamp {
                return isAscending
                    ? lhs.createdTimestamp < rhs.createdTimestamp
                    : lhs.createdTimestamp > rhs.createdTimestamp
            }
            return compareNames(
                lhs.name,
                rhs.name,
                ascending: true
            )
        case .madeCount:
            let lhsCount = lhs.diaryObjects.orEmpty.count
            let rhsCount = rhs.diaryObjects.orEmpty.count

            if lhsCount != rhsCount {
                return isAscending
                    ? lhsCount < rhsCount
                    : lhsCount > rhsCount
            }
            return compareNames(
                lhs.name,
                rhs.name,
                ascending: true
            )
        }
    }

    static func compareNames(
        _ lhs: String,
        _ rhs: String,
        ascending: Bool
    ) -> Bool {
        let comparison = lhs.localizedStandardCompare(rhs)
        if comparison == .orderedSame {
            return false
        }
        if ascending {
            return comparison == .orderedAscending
        }
        return comparison == .orderedDescending
    }
}
