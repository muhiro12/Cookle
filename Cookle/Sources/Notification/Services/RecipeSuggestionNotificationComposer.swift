import Foundation
import UserNotifications

struct RecipeSuggestionNotificationComposer {
    private let attachmentStore: NotificationAttachmentStore

    init(attachmentStore: NotificationAttachmentStore) {
        self.attachmentStore = attachmentStore
    }

    func content(
        for recipe: Recipe,
        stableIdentifier: String
    ) -> UNMutableNotificationContent {
        let recipeName = recipeTitle(for: recipe)
        let hasPhoto = recipe.photoObjects?.sorted().first?.photo != nil
            || recipe.photos?.isEmpty == false
        let attachment = attachmentStore.attachment(
            for: recipe,
            stableIdentifier: stableIdentifier
        )
        return makeContent(
            title: recipeName,
            subtitle: subtitle(for: recipe),
            body: body(for: recipe, recipeName: recipeName),
            routeURL: routeURL(for: stableIdentifier),
            stableIdentifier: stableIdentifier,
            relevanceScore: hasPhoto ? 0.8 : 0.6,
            attachment: attachment
        )
    }

    func fallbackContent(
        recipeName: String,
        stableIdentifier: String? = nil
    ) -> UNMutableNotificationContent {
        let resolvedStableIdentifier = stableIdentifier ?? .empty
        return makeContent(
            title: String(localized: "Recipe Suggestion"),
            subtitle: .empty,
            body: String(localized: "How about making \(recipeName) today?"),
            routeURL: routeURL(for: resolvedStableIdentifier),
            stableIdentifier: resolvedStableIdentifier,
            relevanceScore: 0.6,
            attachment: nil
        )
    }
}

private extension RecipeSuggestionNotificationComposer {
    func makeContent(
        title: String,
        subtitle: String,
        body: String,
        routeURL: URL,
        stableIdentifier: String,
        relevanceScore: Double,
        attachment: UNNotificationAttachment?
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default
        content.interruptionLevel = .active
        content.threadIdentifier = NotificationConstants.suggestionThreadIdentifier
        content.categoryIdentifier = NotificationConstants.suggestionCategoryIdentifier
        content.targetContentIdentifier = stableIdentifier.isEmpty
            ? "recipe"
            : "recipe:\(stableIdentifier)"
        content.relevanceScore = relevanceScore
        content.userInfo = [
            NotificationConstants.routeURLUserInfoKey: routeURL.absoluteString,
            NotificationConstants.contentKindUserInfoKey: NotificationConstants.recipeSuggestionContentKind,
            NotificationConstants.stableIdentifierUserInfoKey: stableIdentifier
        ]
        if let attachment {
            content.attachments = [attachment]
        }
        return content
    }

    func routeURL(for stableIdentifier: String) -> URL {
        guard stableIdentifier.isNotEmpty else {
            return CookleDeepLinkURLBuilder.preferredRecipeURL()
        }
        return CookleDeepLinkURLBuilder.preferredRecipeDetailURL(
            for: stableIdentifier
        )
    }

    func recipeTitle(for recipe: Recipe) -> String {
        let trimmedName = recipe.name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmedName.isNotEmpty ? trimmedName : String(localized: "Recipe")
    }

    func body(for recipe: Recipe, recipeName: String) -> String {
        RecipeBlurbService.makeBlurb(
            request: .init(
                steps: recipe.steps,
                ingredients: recipe.ingredientObjects?.sorted().compactMap { object in
                    object.ingredient?.value
                } ?? [],
                note: recipe.note
            )
        ) ?? String(localized: "How about making \(recipeName) today?")
    }

    func subtitle(for recipe: Recipe) -> String {
        var segments = [String]()

        if recipe.cookingTime > 0 {
            segments.append("\(recipe.cookingTime) min")
        }

        if recipe.servingSize > 0 {
            if recipe.servingSize == 1 {
                segments.append("1 serving")
            } else {
                segments.append("\(recipe.servingSize) \(String(localized: "servings"))")
            }
        }

        let ingredientCount = recipe.ingredientObjects?.count ?? .zero
        if ingredientCount > 0 {
            if ingredientCount == 1 {
                segments.append("1 ingredient")
            } else {
                segments.append("\(ingredientCount) ingredients")
            }
        }

        return segments.joined(separator: " | ")
    }
}
