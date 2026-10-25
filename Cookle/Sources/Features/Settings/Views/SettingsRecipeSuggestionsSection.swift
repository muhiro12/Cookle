import MHPlatform
import SwiftUI
import TipKit
import UIKit

struct SettingsRecipeSuggestionsSection: View {
    let model: SettingsScreenModel
    let tip: (any Tip)?

    @Environment(NotificationService.self)
    private var notificationService
    @Environment(SettingsActionService.self)
    private var settingsActionService
    @Environment(\.openURL)
    private var openURL
    @Environment(\.locale)
    private var locale

    @AppStorage(\.recipeSuggestionNotificationMode, default: "adaptive")
    private var storedMode
    @AppStorage(\.dailyRecipeSuggestionHour)
    private var hour
    @AppStorage(\.dailyRecipeSuggestionMinute)
    private var minute

    var body: some View {
        Section {
            Picker("Recipe suggestions", selection: $storedMode) {
                Text("Off").tag(RecipeSuggestionNotificationMode.off.rawValue)
                Text("At a set time").tag(RecipeSuggestionNotificationMode.fixed.rawValue)
                Text("Adaptive").tag(RecipeSuggestionNotificationMode.adaptive.rawValue)
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("recipe-suggestion-mode")
            .disabled(!notificationService.isAuthorizationGranted)
            .cooklePopoverTip(tip, arrowEdge: .top)

            if notificationService.authorizationStatus == .notDetermined {
                Button("Allow notifications") {
                    Task {
                        await notificationService.requestSettingsAuthorizationIfNeeded()
                    }
                }
            } else if !notificationService.isAuthorizationGranted {
                Button("Open Notification Settings", action: openNotificationSettings)
            }

            fixedTimingControls

            if mode != .off, notificationService.isAuthorizationGranted {
                Button("Send test notification") {
                    Task {
                        await model.sendTestSuggestionNotification(notificationService: notificationService)
                    }
                }
                .disabled(model.isManageActionInProgress)
            }
        } header: {
            Text("Recipe Suggestion Notifications")
        } footer: {
            VStack(alignment: .leading) {
                Text(statusDescription)
                if mode != .off, notificationService.isAuthorizationGranted {
                    nextSuggestionDescription
                }
            }
        }
        .onChange(of: storedMode, applySettings)
        .onChange(of: hour, applySettings)
        .onChange(of: minute, applySettings)
    }

    private var nextSuggestionDescription: some View {
        TimelineView(.explicit(notificationService.scheduledSuggestionDates)) { timeline in
            if let date = notificationService.scheduledSuggestionDates.first(where: { $0 > timeline.date }) {
                Text("Next notification: \(date.formatted(.dateTime.month().day().hour().minute().locale(locale)))")
            } else {
                Text("No upcoming recipe suggestions.")
            }
        }
    }

    @ViewBuilder private var fixedTimingControls: some View {
        if mode == .fixed {
            DatePicker("Notify time", selection: fixedTime, displayedComponents: .hourAndMinute)
                .disabled(!notificationService.isAuthorizationGranted)
            Text("Cookle also learns meal times while you use fixed timing.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Use adaptive timing") {
                storedMode = RecipeSuggestionNotificationMode.adaptive.rawValue
            }
            .disabled(!notificationService.isAuthorizationGranted)
        }
    }

    private var mode: RecipeSuggestionNotificationMode {
        RecipeSuggestionNotificationMode(rawValue: storedMode) ?? .adaptive
    }

    private var fixedTime: Binding<Date> {
        .init {
            DailySuggestionTimePolicy.date(hour: hour, minute: minute)
        } set: { value in
            let components = DailySuggestionTimePolicy.components(from: value)
            hour = components.hour
            minute = components.minute
        }
    }

    private var statusDescription: String {
        guard notificationService.isAuthorizationGranted else {
            return String(localized: """
                Allow notifications in iOS to change recipe suggestion settings. \
                Your selected mode is kept.
                """)
        }
        switch mode {
        case .off:
            return String(localized: "Recipe suggestions are off. Cookle does not record meal times while Off.")
        case .fixed:
            return String(localized: "Daily recipe suggestions are enabled and will arrive at your selected time.")
        case .adaptive:
            if notificationService.suggestionState.learnedMinutes.isEmpty {
                return String(localized: """
                Cookle learns meal times from independent use on this device. \
                Learning needs at least two days; no suggestions are scheduled yet.
                """)
            }
            return String(localized: """
                Suggestions follow your recent use, up to one per meal and three per day. \
                Opening Cookle skips that meal's remaining suggestion today.
                """)
        }
    }

    private func applySettings() {
        Task {
            await model.applyNotificationSettings(settingsActionService: settingsActionService)
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
