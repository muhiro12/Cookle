@preconcurrency import MHPlatform
import UserNotifications

extension NotificationService {
    nonisolated static func routeMetadata(
        response: UNNotificationResponse,
        outcome: MHNotificationRouteDeliveryOutcome
    ) -> [String: String] {
        var metadata = [
            "action_identifier": response.actionIdentifier,
            "delivery_source": String(describing: outcome.source)
        ]
        metadata["route_url"] = outcome.routeURL?.absoluteString ?? ""
        return metadata
    }

    func handleDisabledSuggestionSyncIfNeeded() async -> Bool {
        guard !CooklePreferences.bool(for: \.isDailyRecipeSuggestionNotificationOn) else {
            return false
        }

        await clearSuggestionsAndAttachments()
        await refreshAuthorizationStatus()
        syncLogger.notice(
            "notification synchronization skipped because feature is disabled",
            metadata: [
                "authorization_status": authorizationStatusValue(
                    authorizationStatus
                )
            ]
        )
        return true
    }

    func handleUnauthorizedStatusIfNeeded(
        status: UNAuthorizationStatus
    ) async -> Bool {
        authorizationStatus = status
        guard isAuthorizationGranted == false else {
            return false
        }

        await clearSuggestionsAndAttachments()
        syncLogger.notice(
            "notification synchronization ended without authorization",
            metadata: [
                "authorization_status": authorizationStatusValue(status)
            ]
        )
        return true
    }

    func clearSuggestionsAndAttachments() async {
        await replaceManagedSuggestionRequests(with: [])
        await syncWorker.removeAllAttachments()
    }

    func logAuthorizationRefresh(
        status: UNAuthorizationStatus,
        requestAuthorizationIfNeeded: Bool
    ) {
        authorizationStatus = status
        syncLogger.notice(
            "notification authorization refreshed",
            metadata: [
                "authorization_status": authorizationStatusValue(status),
                "request_if_not_determined": requestAuthorizationIfNeeded.description
            ]
        )
    }

    func logPlanBuilt(
        _ plan: NotificationSyncWorker.Plan
    ) {
        syncLogger.notice(
            "notification plan built",
            metadata: planMetadata(plan)
        )
    }

    func applyPlan(
        _ plan: NotificationSyncWorker.Plan
    ) async {
        let requestApplyStartedAt = Date.timeIntervalSinceReferenceDate
        await replaceManagedSuggestionRequests(
            with: plan.preparedRequests.map(suggestionRequest)
        )
        var metadata = planMetadata(plan)
        metadata["duration_ms"] = durationMilliseconds(
            since: requestApplyStartedAt
        ).description
        syncLogger.notice(
            "notification request apply finished",
            metadata: metadata
        )
    }

    nonisolated func deliverRoute(
        for response: UNNotificationResponse
    ) async -> MHNotificationRouteDeliveryOutcome {
        let payload = NotificationConstants.payloadCodec.decode(
            response.notification.request.content.userInfo
        )
        let responseContext = MHNotificationResponseContext(
            actionIdentifier: response.actionIdentifier
        )
        let routeDestination = await MainActor.run {
            routeInbox
        }
        return await MHNotificationOrchestrator.deliverRouteURL(
            payload: payload,
            response: responseContext,
            destination: routeDestination,
            fallbackRouteURL: Self.fallbackRouteURL
        )
    }

    nonisolated func logRouteDeliveryOutcome(
        _ outcome: MHNotificationRouteDeliveryOutcome,
        response: UNNotificationResponse
    ) {
        let metadata = Self.routeMetadata(
            response: response,
            outcome: outcome
        )

        switch outcome.source {
        case .payload:
            routeLogger.info(
                "notification route resolved",
                metadata: metadata
            )
        case .fallback where response.actionIdentifier
                == NotificationConstants.browseRecipesActionIdentifier:
            routeLogger.notice(
                "notification route resolved via browse fallback",
                metadata: metadata
            )
        case .fallback where response.actionIdentifier == UNNotificationDefaultActionIdentifier:
            routeLogger.info(
                "notification route resolved via default fallback",
                metadata: metadata
            )
        case .fallback:
            routeLogger.info(
                "notification route resolved via fallback",
                metadata: metadata
            )
        case .noRoute:
            routeLogger.info(
                "notification route resolution returned no route",
                metadata: metadata
            )
        }
    }

    func planMetadata(
        _ plan: NotificationSyncWorker.Plan
    ) -> [String: String] {
        [
            "prepared_request_count": plan.preparedRequests.count.description,
            "attachment_count": plan.preparedRequests.compactMap(
                \.attachmentFileURL
            ).count.description,
            "notification_hour": notificationHour.description,
            "notification_minute": notificationMinute.description
        ]
    }

    func authorizationStatusValue(
        _ status: UNAuthorizationStatus
    ) -> String {
        switch status {
        case .notDetermined:
            "not_determined"
        case .denied:
            "denied"
        case .authorized:
            "authorized"
        case .provisional:
            "provisional"
        case .ephemeral:
            "ephemeral"
        @unknown default:
            "unknown"
        }
    }
}
