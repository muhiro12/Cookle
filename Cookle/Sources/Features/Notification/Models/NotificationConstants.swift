import Foundation
import MHPlatform

enum NotificationConstants {
    nonisolated static let recipeSuggestionContentKind = CookleNotificationIdentifiers.recipeSuggestionContentKind
    nonisolated static let cookingTimerContentKind = CookleNotificationIdentifiers.cookingTimerContentKind
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

    nonisolated static let suggestionCategoryDescriptor: MHNotificationCategoryDescriptor = .init(
        identifier: CookleNotificationIdentifiers.suggestionCategoryIdentifier,
        actions: [
            .init(
                identifier: CookleNotificationIdentifiers.browseRecipesActionIdentifier,
                title: String(localized: "Browse Recipes")
            )
        ]
    )
}
