import Foundation
import FoundationModels
import SwiftData

/// Recipe-related domain services.
@preconcurrency
@MainActor
public enum RecipeService {
    /// Returns the last opened recipe stored in preferences, if available.
    /// - Parameters:
    ///   - context: Model context to query.
    /// - Returns: The matching `Recipe` or `nil` when not found.
    public static func lastOpenedRecipe(context: ModelContext) throws -> Recipe? {
        try lastOpenedRecipe(
            context: context,
            lastOpenedRecipeID: CookleSharedPreferences.string(for: \.lastOpenedRecipeID)
        )
    }

    /// Returns the last opened recipe stored in preferences, if available.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - lastOpenedRecipeID: Optional base64-encoded persistent identifier.
    /// - Returns: The matching `Recipe` or `nil` when not found.
    public static func lastOpenedRecipe(
        context: ModelContext,
        lastOpenedRecipeID: String?
    ) throws -> Recipe? {
        guard let lastOpenedRecipeID else {
            return nil
        }
        return try RecipeStableIdentifierCodec.recipe(
            from: lastOpenedRecipeID,
            context: context
        )
    }

    /// Returns any single recipe from the store.
    /// - Parameter context: Model context to query.
    /// - Returns: A random `Recipe` or `nil` when the store is empty.
    public static func randomRecipe(context: ModelContext) throws -> Recipe? {
        try context.fetchRandom(.recipes(.all))
    }

    /// Returns the most recently updated recipe.
    public static func latestRecipe(context: ModelContext) throws -> Recipe? {
        let descriptor: FetchDescriptor<Recipe> = .init(
            sortBy: [
                .init(\.modifiedTimestamp, order: .reverse),
                .init(\.createdTimestamp, order: .reverse),
                .init(\.name)
            ]
        )
        return try context.fetch(descriptor).first
    }

    /// Orders already-loaded recipes using the repository's canonical browse semantics.
    /// - Parameters:
    ///   - recipes: In-memory recipes to order for a browse surface.
    ///   - sortMode: Sort mode to apply.
    ///   - isAscending: Sort direction.
    /// - Returns: The ordered recipes.
    public static func browse(
        _ recipes: [Recipe],
        sortMode: RecipeBrowseSortMode,
        isAscending: Bool
    ) -> [Recipe] {
        sortedRecipes(
            recipes,
            criteria: .init(
                searchText: "",
                sortMode: sortMode,
                isAscending: isAscending
            )
        )
    }

    /// Searches and sorts recipes using the repository's canonical browse semantics.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - criteria: Shared browse criteria including text search and sort mode.
    /// - Returns: Matching recipes ordered for the caller's browse surface.
    public static func search(
        context: ModelContext,
        criteria: RecipeBrowseCriteria
    ) throws -> [Recipe] {
        let predicate: RecipePredicate = if criteria.searchText.isEmpty {
            .all
        } else {
            .anyTextMatches(criteria.searchText)
        }
        let recipes = try context.fetch(.recipes(predicate))
        return sortedRecipes(
            recipes,
            criteria: criteria
        )
    }

    /// Searches recipes by a unified text condition that matches name, ingredients, or categories.
    /// - Parameters:
    ///   - context: Model context to query.
    ///   - text: Search text. Short text (< 3 chars) uses equality for tags; otherwise partial match.
    /// - Returns: Matching recipes ordered by name.
    public static func search(context: ModelContext, text: String) throws -> [Recipe] {
        try search(
            context: context,
            criteria: .init(
                searchText: text,
                sortMode: .alphabetical,
                isAscending: true
            )
        )
    }

    /// Deletes the supplied recipe from the store.
    public static func delete(
        context: ModelContext,
        recipe: Recipe
    ) {
        _ = deleteWithOutcome(
            context: context,
            recipe: recipe
        )
    }

    /// Deletes the supplied recipe and returns follow-up hints.
    public static func deleteWithOutcome(
        context: ModelContext,
        recipe: Recipe
    ) -> MutationOutcome<Void> {
        context.delete(recipe)
        return .init(
            value: (),
            effects: [
                .recipeDataChanged,
                .notificationPlanChanged
            ]
        )
    }

    /// Removes one persisted photo row from a recipe and returns follow-up hints.
    public static func removePhotoWithOutcome(
        context: ModelContext,
        recipe: Recipe,
        photoObject: PhotoObject
    ) -> MutationOutcome<Void> {
        let remainingPhotoObjects = recipe.photoObjects.orEmpty.filter { currentPhotoObject in
            currentPhotoObject.persistentModelID != photoObject.persistentModelID
        }

        context.delete(photoObject)
        recipe.update(
            name: recipe.name,
            photos: remainingPhotoObjects,
            servingSize: recipe.servingSize,
            cookingTime: recipe.cookingTime,
            ingredients: recipe.ingredientObjects.orEmpty,
            steps: recipe.steps,
            categories: recipe.categories.orEmpty,
            note: recipe.note
        )

        return .init(
            value: (),
            effects: [
                .recipeDataChanged,
                .notificationPlanChanged
            ]
        )
    }

    /// Stores the current recipe as the last opened target.
    public static func recordLastOpenedRecipe(_ recipe: Recipe) {
        _ = recordLastOpenedRecipeWithOutcome(
            recipe
        )
    }

    /// Stores the current recipe as the last opened target and returns follow-up hints.
    public static func recordLastOpenedRecipeWithOutcome(
        _ recipe: Recipe
    ) -> MutationOutcome<Void> {
        let encodedRecipeID = RecipeStableIdentifierCodec.encodeIfPossible(
            recipe.id
        )
        CookleSharedPreferences.set(
            encodedRecipeID,
            for: \.lastOpenedRecipeID
        )
        return .init(
            value: (),
            effects: [
                .recipeDataChanged
            ]
        )
    }

    // LLM-based inference with a graceful heuristic fallback.
    /// Infers a recipe structure from free-form text using an LLM, with a heuristic fallback.
    /// - Parameter text: Free-form user text describing a recipe.
    /// - Returns: An `InferredRecipe` with best-effort fields filled.
    @available(iOS 26.0, *)
    public static func infer(text: String) async -> InferredRecipe {
        let languageName = inferredLanguageName()

        let instructions = """
            You are a professional chef and culinary expert running a recipe website.
            Kindly and thoroughly teach users how to prepare recipes.
            Make your explanations easy to follow and friendly for home cooks of any skill level.
            """
        let session = LanguageModelSession(instructions: instructions)

        let prompt = inferencePrompt(
            languageName: languageName,
            text: text
        )

        do {
            return try await session.respond(
                to: prompt,
                generating: InferredRecipe.self
            ).content
        } catch {
            return fallbackInference(from: text)
        }
    }
}

@available(iOS 26.0, *)
private extension RecipeService {
    static func inferredLanguageName() -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let locale = Locale.current
        return locale.localizedString(forLanguageCode: languageCode) ?? "English"
    }

    static func inferencePrompt(
        languageName: String,
        text: String
    ) -> String {
        """
        Analyze the following text and provide a recipe form. Please respond in \(languageName).
        """ + "\n" + text
    }

    static func fallbackInference(from text: String) -> InferredRecipe {
        let lines = text.split(separator: "\n").map(String.init)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = firstLine?.isEmpty == false ? firstLine ?? "Recipe" : "Recipe"
        let sourceText = lines.joined(separator: " ")

        return .init(
            name: name,
            servingSize: extractedNumber(
                in: sourceText,
                pattern: #"(?i)(serves|for)\s*(\d+)"#
            ),
            cookingTime: extractedNumber(
                in: sourceText,
                pattern: #"(?i)(\d+)\s*(min|minutes)"#
            ),
            ingredients: [],
            steps: [],
            categories: [],
            note: ""
        )
    }

    static func extractedNumber(
        in sourceText: String,
        pattern: String
    ) -> Int {
        guard let match = sourceText.range(
            of: pattern,
            options: .regularExpression
        ) else {
            return .zero
        }
        let matchedText = String(sourceText[match])
        let digits = matchedText
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        return Int(digits) ?? .zero
    }
}

private extension RecipeService {
    static func sortedRecipes(
        _ recipes: [Recipe],
        criteria: RecipeBrowseCriteria
    ) -> [Recipe] {
        recipes.sorted { lhs, rhs in
            comesBefore(
                lhs,
                rhs,
                sortMode: criteria.sortMode,
                isAscending: criteria.isAscending
            )
        }
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
