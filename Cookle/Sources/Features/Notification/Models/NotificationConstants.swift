import Foundation
import MHPlatform

enum NotificationConstants {
    nonisolated static let recipeSuggestionContentKind = "recipeSuggestion"
    nonisolated static let cookingTimerContentKind = "cookingTimer"
    nonisolated static let routeURLUserInfoKey = "routeURL"
    nonisolated static let fallbackRouteURLUserInfoKey = "fallbackRouteURL"
    nonisolated static let actionRouteURLsUserInfoKey = "actionRouteURLs"
    nonisolated static let contentKindUserInfoKey = "contentKind"
    nonisolated static let stableIdentifierUserInfoKey = "stableIdentifier"
    nonisolated static let cookingTimerKeyUserInfoKey = "cookingTimerKey"
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

    // Delivered notifications may outlive an app update, so their category and
    // action identifiers must stay registered and routable.
    nonisolated static var suggestionCategoryDescriptors: [MHNotificationCategoryDescriptor] {
        [
            suggestionCategoryDescriptor(
                identifier: CookleNotificationIdentifiers.suggestionCategoryIdentifier,
                actionIdentifier: CookleNotificationIdentifiers.browseRecipesActionIdentifier
            ),
            suggestionCategoryDescriptor(
                identifier: CookleNotificationIdentifiers.legacySuggestionCategoryIdentifier,
                actionIdentifier: CookleNotificationIdentifiers.legacyBrowseRecipesActionIdentifier
            )
        ]
    }

    nonisolated private static func suggestionCategoryDescriptor(
        identifier: String,
        actionIdentifier: String
    ) -> MHNotificationCategoryDescriptor {
        .init(
            identifier: identifier,
            actions: [
                .init(
                    identifier: actionIdentifier,
                    title: String(localized: "Browse Recipes")
                )
            ]
        )
    }
}
