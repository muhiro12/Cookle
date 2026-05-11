//
//  SettingsSidebarView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import MHPlatform
import SwiftUI
import TipKit
import UIKit

struct SettingsSidebarView: View {
    @State private var model = SettingsScreenModel()
    @State private var isDebugPresented = false

    @Environment(\.modelContext)
    private var context
    @Environment(\.isPresented)
    private var isPresented
    @Environment(\.openURL)
    private var openURL
    @Environment(NotificationService.self)
    private var notificationService
    @Environment(CookleTipController.self)
    private var tipController
    @Environment(SettingsActionService.self)
    private var settingsActionService

    @AppStorage(\.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(\.isICloudOn)
    private var isICloudOn
    @AppStorage(\.isDebugOn)
    private var isDebugOn
    @AppStorage(\.isDailyRecipeSuggestionNotificationOn)
    private var isDailyRecipeSuggestionNotificationOn
    @AppStorage(\.dailyRecipeSuggestionHour)
    private var dailyRecipeSuggestionHour
    @AppStorage(\.dailyRecipeSuggestionMinute)
    private var dailyRecipeSuggestionMinute

    @Binding private var content: SettingsContent?

    private let dailySuggestionTip = DailySuggestionTip()
    private let subscriptionTip = SubscriptionTip()
    private let shortcutsTip = ShortcutsTip()

    var body: some View {
        @Bindable var model = model

        settingsList
            .cookleTopLevelNavigationChrome("Settings")
            .toolbar {
                ToolbarItem {
                    CloseButton()
                        .hidden(!isPresented)
                }
            }
            .settingsDataManagementDialogs(
                model: model,
                modelContainer: context.container,
                settingsActionService: settingsActionService
            )
            .alert(
                Text("Cannot Complete Settings Action"),
                isPresented: isErrorPresentedBinding
            ) {
                Button("OK", role: .cancel) {
                    model.errorMessage = nil
                }
            } message: {
                Text(model.errorMessage ?? "")
            }
            .task {
                await model.prepareNotificationSettings(
                    settingsActionService: settingsActionService
                )
                refreshTipEligibility()
            }
            .task {
                await model.observeDailySuggestionTipEligibility(
                    dailySuggestionTip
                )
            }
            .task {
                await model.observeSubscriptionTipEligibility(
                    subscriptionTip
                )
            }
            .task {
                await model.observeShortcutsTipEligibility(
                    shortcutsTip
                )
            }
            .onChange(of: isDailyRecipeSuggestionNotificationOn) {
                refreshTipEligibility()
                applyNotificationSettings()
            }
            .onChange(of: dailyRecipeSuggestionHour) {
                applyNotificationSettings()
            }
            .onChange(of: dailyRecipeSuggestionMinute) {
                applyNotificationSettings()
            }
            .onChange(of: isSubscribeOn) {
                refreshTipEligibility()
            }
            .onAppear {
                refreshTipEligibility()
            }
            .fullScreenCover(isPresented: $isDebugPresented) {
                DebugNavigationView()
            }
    }

    var settingsList: some View {
        List {
            subscriptionSection
            iCloudSection
            notificationSection
            SettingsDataManagementSection(
                model: model
            )
            generalSection
            ShortcutsLinkSection(
                tip: currentSettingsTip(
                    for: shortcutsTip,
                    isEligible: shouldShowShortcutsTip
                )
            )
        }
        .cookleFloatingTabBarScrollMargins()
    }

    var subscriptionSection: some View {
        Section {
            Button {
                content = .subscription
            } label: {
                Text("Subscription")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .cooklePopoverTip(
                currentSettingsTip(
                    for: subscriptionTip,
                    isEligible: shouldShowSubscriptionTip
                ),
                arrowEdge: .top
            )
            .accessibilityAddTraits(.isButton)
            .simultaneousGesture(
                TapGesture().onEnded {
                    tipController.donateDidOpenSubscription()
                }
            )
        }
        .hidden(isSubscribeOn)
    }

    var iCloudSection: some View {
        Section {
            Toggle("iCloud On", isOn: $isICloudOn)
        } header: {
            Text("Settings")
        }
        .hidden(!isSubscribeOn)
    }

    var notificationSection: some View {
        Section("Recipe Suggestion Notifications") {
            Toggle("Daily recipe suggestions", isOn: $isDailyRecipeSuggestionNotificationOn)
                .cooklePopoverTip(
                    currentSettingsTip(
                        for: dailySuggestionTip,
                        isEligible: shouldShowDailySuggestionTip
                    ),
                    arrowEdge: .top
                )
            Text(notificationStatusDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if notificationService.authorizationStatus == .denied {
                Button("Open Notification Settings") {
                    openNotificationSettings()
                }
            }
            if isDailyRecipeSuggestionNotificationOn {
                DatePicker(
                    "Notify time",
                    selection: dailySuggestionTime,
                    displayedComponents: .hourAndMinute
                )
                if notificationService.authorizationStatus != .denied {
                    Button("Send test notification") {
                        Task {
                            await notificationService.sendTestSuggestionNotification()
                        }
                    }
                }
            }
        }
    }

    var generalSection: some View {
        Section {
            if isDebugOn {
                Button {
                    isDebugPresented = true
                } label: {
                    Text("Debug")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            Button {
                content = .license
            } label: {
                Text("Licenses")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Button("Show tips again") {
                do {
                    try tipController.resetTips()
                    refreshTipEligibility()
                } catch {
                    model.errorMessage = error.localizedDescription
                }
            }
        }
    }

    init(selection: Binding<SettingsContent?> = .constant(nil)) {
        self._content = selection
    }
}

private extension SettingsSidebarView {
    var shouldShowDailySuggestionTip: Bool {
        isDailyRecipeSuggestionNotificationOn == false && model.isDailySuggestionTipEligible
    }

    var shouldShowSubscriptionTip: Bool {
        isSubscribeOn == false
            && shouldShowDailySuggestionTip == false
            && model.isSubscriptionTipEligible
    }

    var shouldShowShortcutsTip: Bool {
        shouldShowDailySuggestionTip == false
            && shouldShowSubscriptionTip == false
            && model.isShortcutsTipEligible
    }

    var isErrorPresentedBinding: Binding<Bool> {
        .init(
            get: {
                model.errorMessage != nil
            },
            set: { isPresented in
                if isPresented == false {
                    model.errorMessage = nil
                }
            }
        )
    }

    var dailySuggestionTime: Binding<Date> {
        .init {
            DailySuggestionTimePolicy.date(
                hour: dailyRecipeSuggestionHour,
                minute: dailyRecipeSuggestionMinute,
                on: .now,
                calendar: .current
            )
        } set: { newValue in
            let components = DailySuggestionTimePolicy.components(
                from: newValue,
                calendar: .current
            )
            dailyRecipeSuggestionHour = components.hour
            dailyRecipeSuggestionMinute = components.minute
        }
    }

    var notificationStatusDescription: String {
        switch notificationService.authorizationStatus {
        case .authorized,
             .provisional,
             .ephemeral:
            if isDailyRecipeSuggestionNotificationOn {
                return String(
                    localized: "Daily recipe suggestions are enabled and will arrive at your selected time."
                )
            }

            return String(localized: "Notifications are allowed. Turn on daily recipe suggestions to receive one recipe suggestion each day.") // swiftlint:disable:this line_length
        case .denied:
            return String(
                localized: "Notifications are disabled in system settings."
            )
        case .notDetermined:
            return String(
                localized: "Allow notifications to get one recipe suggestion each day at your selected time."
            )
        @unknown default:
            return String(
                localized: "Allow notifications to get one recipe suggestion each day at your selected time."
            )
        }
    }

    func applyNotificationSettings() {
        Task {
            await model.applyNotificationSettings(
                settingsActionService: settingsActionService
            )
        }
    }

    func openNotificationSettings() {
        if let notificationSettingsURL = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(notificationSettingsURL)
            return
        }
        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
            openURL(appSettingsURL)
        }
    }

    func refreshTipEligibility() {
        model.refreshTipEligibility(
            dailySuggestionTip: dailySuggestionTip,
            subscriptionTip: subscriptionTip,
            shortcutsTip: shortcutsTip
        )
    }

    func currentSettingsTip<T: Tip>(
        for tip: T,
        isEligible: Bool
    ) -> (any Tip)? {
        guard isEligible else {
            return nil
        }

        return model.currentTip(
            for: tip,
            context: .init(
                dailySuggestionTipID: dailySuggestionTip.id,
                subscriptionTipID: subscriptionTip.id,
                shortcutsTipID: shortcutsTip.id,
                shouldShowDailySuggestionTip: shouldShowDailySuggestionTip,
                shouldShowSubscriptionTip: shouldShowSubscriptionTip,
                shouldShowShortcutsTip: shouldShowShortcutsTip
            )
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        SettingsSidebarView()
    }
}
