import UserNotifications

nonisolated private struct NotificationResponseDelivery: @unchecked Sendable {
    let response: UNNotificationResponse
    let completionHandler: () -> Void
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let identifier = notification.request.identifier
        let isSuggestion = CookleNotificationIdentifiers.isScheduledSuggestionIdentifier(identifier)
        if isSuggestion {
            let hasUsedMeal = await hasUsedCurrentMealToday()
            if hasUsedMeal {
                return []
            }
        }
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
            if Self.opensApp(delivery.response) {
                recordNotificationOpen(deliveredAt: delivery.response.notification.date)
            }
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

extension NotificationService {
    nonisolated static func opensApp(_ response: UNNotificationResponse) -> Bool {
        response.actionIdentifier == UNNotificationDefaultActionIdentifier
            || response.actionIdentifier == CookleNotificationIdentifiers.browseRecipesActionIdentifier
    }

    private func hasUsedCurrentMealToday() -> Bool {
        guard CooklePreferences.suggestionNotificationMode == .adaptive else {
            return false
        }
        let now = Date.now
        let calendar = Calendar.current
        let meal = DiaryOperations.mealType(for: now, calendar: calendar)
        guard let usedAt = suggestionState.lastUsedAt[meal] else {
            return false
        }
        return calendar.isDate(usedAt, inSameDayAs: now)
    }
}
