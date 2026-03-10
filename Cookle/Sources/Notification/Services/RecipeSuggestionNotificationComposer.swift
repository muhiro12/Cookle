import Foundation
import MHNotificationPayloads
import UserNotifications

struct RecipeSuggestionNotificationComposer {
    private enum RelevanceScore {
        static let withPhoto = Double("0.8") ?? .zero
        static let fallback = Double("0.6") ?? .zero
    }

    func content(
        for snapshot: NotificationRecipeSnapshot,
        attachmentFileURL: URL?
    ) -> UNMutableNotificationContent {
        let recipeName = recipeTitle(for: snapshot)
        return makeContent(
            .init(
                title: recipeName,
                subtitle: subtitle(for: snapshot),
                body: body(for: snapshot, recipeName: recipeName),
                routeURL: routeURL(for: snapshot.stableIdentifier),
                stableIdentifier: snapshot.stableIdentifier,
                relevanceScore: snapshot.hasPhoto ? RelevanceScore.withPhoto : RelevanceScore.fallback,
                attachmentFileURL: attachmentFileURL
            )
        )
    }

    func fallbackContent(
        recipeName: String,
        stableIdentifier: String? = nil
    ) -> UNMutableNotificationContent {
        let resolvedStableIdentifier = stableIdentifier ?? .empty
        return makeContent(
            .init(
                title: String(localized: "Recipe Suggestion"),
                subtitle: .empty,
                body: String(localized: "How about making \(recipeName) today?"),
                routeURL: routeURL(for: resolvedStableIdentifier),
                stableIdentifier: resolvedStableIdentifier,
                relevanceScore: RelevanceScore.fallback,
                attachmentFileURL: nil
            )
        )
    }
}

private extension RecipeSuggestionNotificationComposer {
    struct ContentInput {
        let title: String
        let subtitle: String
        let body: String
        let routeURL: URL
        let stableIdentifier: String
        let relevanceScore: Double
        let attachmentFileURL: URL?
    }

    func makeContent(_ input: ContentInput) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = input.title
        content.subtitle = input.subtitle
        content.body = input.body
        content.sound = .default
        content.interruptionLevel = .active
        content.threadIdentifier = NotificationConstants.suggestionThreadIdentifier
        content.categoryIdentifier = NotificationConstants.suggestionCategoryIdentifier
        content.targetContentIdentifier = input.stableIdentifier.isEmpty
            ? "recipe"
            : "recipe:\(input.stableIdentifier)"
        content.relevanceScore = input.relevanceScore
        content.userInfo = NotificationConstants.payloadCodec.encode(
            .init(
                routes: .init(
                    defaultRouteURL: input.routeURL,
                    actionRouteURLs: [
                        NotificationConstants.browseRecipesActionIdentifier:
                            CookleDeepLinkURLBuilder.preferredRecipeURL()
                    ]
                ),
                metadata: [
                    NotificationConstants.contentKindUserInfoKey:
                        NotificationConstants.recipeSuggestionContentKind,
                    NotificationConstants.stableIdentifierUserInfoKey:
                        input.stableIdentifier
                ]
            )
        )
        if let attachmentFileURL = input.attachmentFileURL,
           let attachment = try? UNNotificationAttachment(
            identifier: input.stableIdentifier,
            url: attachmentFileURL
           ) {
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

    func recipeTitle(for snapshot: NotificationRecipeSnapshot) -> String {
        let trimmedName = snapshot.name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmedName.isNotEmpty ? trimmedName : String(localized: "Recipe")
    }

    func body(
        for snapshot: NotificationRecipeSnapshot,
        recipeName: String
    ) -> String {
        RecipeBlurbService.makeBlurb(
            request: .init(
                steps: snapshot.steps,
                ingredients: snapshot.ingredientNames,
                note: snapshot.note
            )
        ) ?? String(localized: "How about making \(recipeName) today?")
    }

    func subtitle(for snapshot: NotificationRecipeSnapshot) -> String {
        var segments = [String]()

        if snapshot.cookingTime > 0 {
            segments.append("\(snapshot.cookingTime) min")
        }

        if snapshot.servingSize > 0 {
            if snapshot.servingSize == 1 {
                segments.append("1 serving")
            } else {
                segments.append("\(snapshot.servingSize) \(String(localized: "servings"))")
            }
        }

        let ingredientCount = snapshot.ingredientCount
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
