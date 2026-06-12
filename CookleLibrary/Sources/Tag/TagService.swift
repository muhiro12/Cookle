import SwiftData

/// Internal tag collaborator used by public Operations.
@preconcurrency
@MainActor
enum TagService {
    private static var tagMutationEffects: MutationEffect {
        [
            .notificationPlanChanged
        ]
    }

    /// Renames an ingredient after trimming whitespace and validating non-empty input.
    static func rename(
        context: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws {
        _ = try renameWithOutcome(
            context: context,
            ingredient: ingredient,
            value: value
        )
    }

    /// Renames an ingredient and returns follow-up hints.
    static func renameWithOutcome(
        context _: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws -> MutationOutcome<Void> {
        let normalizedValue = try normalized(value)
        ingredient.update(value: normalizedValue)
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }

    /// Renames a category after trimming whitespace and validating non-empty input.
    static func rename(
        context: ModelContext,
        category: Category,
        value: String
    ) throws {
        _ = try renameWithOutcome(
            context: context,
            category: category,
            value: value
        )
    }

    /// Renames a category and returns follow-up hints.
    static func renameWithOutcome(
        context _: ModelContext,
        category: Category,
        value: String
    ) throws -> MutationOutcome<Void> {
        let normalizedValue = try normalized(value)
        category.update(value: normalizedValue)
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }

    /// Deletes a category and returns follow-up hints.
    static func deleteWithOutcome(
        context: ModelContext,
        category: Category
    ) -> MutationOutcome<Void> {
        context.delete(category)
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }

    /// Deletes an unused ingredient and returns follow-up hints.
    static func deleteWithOutcome(
        context: ModelContext,
        ingredient: Ingredient
    ) throws -> MutationOutcome<Void> {
        guard ingredient.recipes.orEmpty.isEmpty else {
            throw TagServiceError.ingredientInUse(ingredient.value)
        }

        context.delete(ingredient)
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }

    /// Returns all tags that look equivalent to `tag` in the supplied collection.
    static func duplicateTags<T: Tag>(
        matching tag: T,
        in tags: [T]
    ) -> [T] {
        let targetKey = duplicateKey(
            for: tag
        )
        return tags.filter { candidate in
            duplicateKey(
                for: candidate
            ) == targetKey
        }
    }

    /// Returns one representative per duplicate-looking group in the supplied collection.
    static func duplicateTags<T: Tag>(
        in tags: [T]
    ) -> [T] {
        Dictionary(grouping: tags) { tag in
            duplicateKey(
                for: tag
            )
        }
        .compactMap { _, group in
            guard group.count > 1 else {
                return nil
            }
            return group.min(
                by: tagComesBefore
            )
        }
        .sorted(
            by: tagComesBefore
        )
    }

    /// Merges duplicate-looking ingredients into the supplied ingredient.
    static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        keeping ingredient: Ingredient
    ) throws -> MutationOutcome<Void> {
        let duplicates = duplicateTags(
            matching: ingredient,
            in: try context.fetch(.ingredients(.all))
        )
        mergeDuplicateIngredients(
            context: context,
            keeping: ingredient,
            duplicates: duplicates
        )
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }

    /// Merges duplicate-looking categories into the supplied category.
    static func mergeDuplicatesWithOutcome(
        context: ModelContext,
        keeping category: Category
    ) throws -> MutationOutcome<Void> {
        let duplicates = duplicateTags(
            matching: category,
            in: try context.fetch(.categories(.all))
        )
        mergeDuplicateCategories(
            context: context,
            keeping: category,
            duplicates: duplicates
        )
        return .init(
            value: (),
            effects: tagMutationEffects
        )
    }
}

private extension TagService {
    static func normalized(_ value: String) throws -> String {
        let normalizedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard normalizedValue.isNotEmpty else {
            throw TagServiceError.emptyValue
        }
        return normalizedValue
    }

    static func duplicateKey<T: Tag>(
        for tag: T
    ) -> String {
        tag.value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter(\.isNotEmpty)
            .joined(separator: " ")
            .folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive,
                    .widthInsensitive
                ],
                locale: .current
            )
    }

    static func mergeDuplicateIngredients(
        context: ModelContext,
        keeping parent: Ingredient,
        duplicates: [Ingredient]
    ) {
        let children = duplicateChildren(
            keeping: parent,
            duplicates: duplicates
        )
        let affectedObjects = uniqueModels(
            children.flatMap(\.objects.orEmpty)
        )
        let affectedRecipes = uniqueModels(
            affectedObjects.compactMap(\.recipe)
        )

        for object in affectedObjects {
            object.update(
                ingredient: parent,
                amount: object.amount,
                order: object.order
            )
        }

        for recipe in affectedRecipes {
            recipe.refreshIngredients()
        }

        for child in children {
            context.delete(child)
        }
    }

    static func mergeDuplicateCategories(
        context: ModelContext,
        keeping parent: Category,
        duplicates: [Category]
    ) {
        let children = duplicateChildren(
            keeping: parent,
            duplicates: duplicates
        )
        let childIDs = Set(
            children.map(\.persistentModelID)
        )
        let affectedRecipes = uniqueModels(
            children.flatMap(\.recipes.orEmpty)
        )

        for recipe in affectedRecipes {
            var categories = recipe.categories.orEmpty.filter { category in
                childIDs.contains(
                    category.persistentModelID
                ) == false
            }
            if categories.contains(where: { category in
                category.persistentModelID == parent.persistentModelID
            }) == false {
                categories.append(parent)
            }
            recipe.updateCategories(
                categories
            )
        }

        for child in children {
            context.delete(child)
        }
    }

    static func duplicateChildren<T: Tag>(
        keeping parent: T,
        duplicates: [T]
    ) -> [T] {
        duplicates.filter { tag in
            tag.persistentModelID != parent.persistentModelID
        }
    }

    static func uniqueModels<Model: PersistentModel>(
        _ models: [Model]
    ) -> [Model] {
        var seenIDs = Set<PersistentIdentifier>()
        var result = [Model]()

        for model in models
        where seenIDs.insert(model.persistentModelID).inserted {
            result.append(model)
        }

        return result
    }

    static func tagComesBefore<T: Tag>(
        _ lhs: T,
        _ rhs: T
    ) -> Bool {
        if lhs.value != rhs.value {
            return lhs.value.localizedStandardCompare(
                rhs.value
            ) == .orderedAscending
        }
        return String(
            describing: lhs.persistentModelID
        ) < String(
            describing: rhs.persistentModelID
        )
    }
}
