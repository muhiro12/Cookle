import Foundation
import MHNotificationPayloads

enum NotificationConstants {
    nonisolated static let suggestionIdentifierPrefix = "daily-recipe-suggestion-"
    nonisolated static let testSuggestionIdentifier = "daily-recipe-suggestion-test"
    nonisolated static let suggestionThreadIdentifier = "daily-recipe-suggestion"
    nonisolated static let suggestionCategoryIdentifier = "daily_recipe_suggestion"
    nonisolated static let browseRecipesActionIdentifier = "browse_recipes"
    nonisolated static let recipeSuggestionContentKind = "recipeSuggestion"
    nonisolated static let routeURLUserInfoKey = "routeURL"
    nonisolated static let fallbackRouteURLUserInfoKey = "fallbackRouteURL"
    nonisolated static let actionRouteURLsUserInfoKey = "actionRouteURLs"
    nonisolated static let contentKindUserInfoKey = "contentKind"
    nonisolated static let stableIdentifierUserInfoKey = "stableIdentifier"
    nonisolated static let attachmentDirectoryName = "NotificationAttachments"
    nonisolated static let attachmentFileNamePrefix = "recipe-"
    nonisolated static let attachmentFileNameSuffix = ".jpg"

    nonisolated static let payloadCodec: MHNotificationPayloadCodec = .init(
        configuration: .init(
            keys: .init(
                defaultRouteURL: routeURLUserInfoKey,
                fallbackRouteURL: fallbackRouteURLUserInfoKey,
                actionRouteURLs: actionRouteURLsUserInfoKey
            ),
            decodableMetadataKeys: [
                contentKindUserInfoKey,
                stableIdentifierUserInfoKey
            ]
        )
    )

    nonisolated static let suggestionCategoryDescriptor: MHNotificationCategoryDescriptor = .init(
        identifier: suggestionCategoryIdentifier,
        actions: [
            .init(
                identifier: browseRecipesActionIdentifier,
                title: "Browse Recipes"
            )
        ]
    )
}
