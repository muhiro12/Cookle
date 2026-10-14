import UIKit
import UserNotifications

/// Reads the cold scene's notification origin before normal foreground recording.
@MainActor
final class CookleNotificationAppDelegate: NSObject, UIApplicationDelegate {
    weak var notificationService: NotificationService? {
        didSet {
            if let pendingNotification, let notificationService {
                notificationService.recordNotificationOpen(
                    deliveredAt: pendingNotification.deliveredAt,
                    at: pendingNotification.openedAt
                )
                self.pendingNotification = nil
            }
        }
    }
    private var pendingNotification: (openedAt: Date, deliveredAt: Date)?

    func application(
        _: UIApplication,
        configurationForConnecting session: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let response = options.notificationResponse, NotificationService.opensApp(response) {
            let openedAt = Date.now
            if let notificationService {
                notificationService.recordNotificationOpen(
                    deliveredAt: response.notification.date,
                    at: openedAt
                )
            } else {
                pendingNotification = (openedAt, response.notification.date)
            }
        }
        return .init(name: nil, sessionRole: session.role)
    }
}
