import Combine
import UIKit

extension NotificationService {
    func recordNotificationOpen(deliveredAt: Date, at date: Date = .now) {
        guard recordsUsage else {
            return
        }
        // UIKit can report activation before its notification response. Undo
        // only this activation's tentative independent sample in that order.
        if let activation = activationBeforeRecording, deliveredAt <= activation.date {
            suggestionState = activation.state
            activationBeforeRecording = nil
        }
        notificationOpenedThisForeground = true
        recordUsage(at: date, isNotificationResponse: true)
        scheduleLifecycleSynchronization()
    }

    func recordForegroundOpen(at date: Date = .now) {
        activationBeforeRecording = (date, suggestionState)
        recordUsage(at: date, isNotificationResponse: notificationOpenedThisForeground)
        scheduleLifecycleSynchronization()
    }

    func recordUsage(at date: Date, isNotificationResponse: Bool) {
        guard recordsUsage, CooklePreferences.suggestionNotificationMode != .off else {
            return
        }
        suggestionState = RecipeOperations.recordSuggestionUsage(
            in: suggestionState,
            at: date,
            isNotificationResponse: isNotificationResponse
        )
        saveSuggestionState()
        syncLogger.info(
            "suggestion usage recorded",
            metadata: ["source": isNotificationResponse ? "notification" : "independent"]
        )
    }

    func saveSuggestionState() {
        guard recordsUsage else {
            return
        }
        guard let value = suggestionState.encodedString() else {
            syncLogger.error("suggestion usage encoding failed")
            return
        }
        CooklePreferences.set(value, for: \.adaptiveRecipeSuggestionState)
    }

    func observeForegroundUsage() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.recordForegroundOpen()
                }
            }
            .store(in: &usageObservers)
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.activationBeforeRecording = nil
                }
            }
            .store(in: &usageObservers)
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.notificationOpenedThisForeground = false
                    self?.activationBeforeRecording = nil
                }
            }
            .store(in: &usageObservers)
    }
}
