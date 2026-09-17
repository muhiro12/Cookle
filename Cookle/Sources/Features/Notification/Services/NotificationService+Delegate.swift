import UserNotifications

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await Task.yield()
        return [.sound, .list, .banner]
    }

    nonisolated func userNotificationCenter(_: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let delivery = NotificationResponseDelivery(
            response: response,
            completionHandler: completionHandler
        )
        Task { @MainActor in
            await handleNotificationResponse(delivery.response)
            delivery.completionHandler()
        }
    }

    nonisolated func userNotificationCenter(_: UNUserNotificationCenter,
                                            openSettingsFor _: UNNotification?) {
        let settingsURL = CookleDeepLinkURLBuilder.preferredURL(for: .settings)
        Task { @MainActor in
            routeLogger.info(
                "notification settings route requested",
                metadata: [
                    "route_url": settingsURL.absoluteString
                ]
            )
            await routeInbox.replacePendingURL(settingsURL)
        }
    }
}

private nonisolated struct NotificationResponseDelivery: @unchecked Sendable {
    let response: UNNotificationResponse
    let completionHandler: () -> Void
}
