//
//  SettingsSidebarView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/17/24.
//

import SwiftUI
import TipKit
import UIKit

struct SettingsSidebarView: View {
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

    @AppStorage(.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(.isICloudOn)
    private var isICloudOn
    @AppStorage(.isDailyRecipeSuggestionNotificationOn)
    private var isDailyRecipeSuggestionNotificationOn
    @AppStorage(.dailyRecipeSuggestionHour)
    private var dailyRecipeSuggestionHour
    @AppStorage(.dailyRecipeSuggestionMinute)
    private var dailyRecipeSuggestionMinute

    @Binding private var content: SettingsContent?

    @State private var isAlertPresented = false
    @State private var isDailySuggestionTipEligible = false
    @State private var isSubscriptionTipEligible = false

    private let dailySuggestionTip = DailySuggestionTip()
    private let subscriptionTip = SubscriptionTip()

    var body: some View {
        settingsList
            .navigationTitle(Text("Settings"))
            .toolbar {
                ToolbarItem {
                    CloseButton()
                        .hidden(!isPresented)
                }
            }
            .confirmationDialog(
                Text("Delete All"),
                isPresented: $isAlertPresented
            ) {
                Button(role: .destructive) {
                    Task {
                        do {
                            try await settingsActionService.deleteAllData(
                                context: context
                            )
                        } catch {
                            assertionFailure(error.localizedDescription)
                        }
                    }
                } label: {
                    Text("Delete")
                }
                Button(role: .cancel) {
                    // Dismisses the confirmation dialog.
                } label: {
                    Text("Cancel")
                }
            } message: {
                Text("Are you sure you want to delete all data?")
            }
            .task {
                await settingsActionService.prepareNotificationSettings()
                refreshTipEligibility()
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
    }

    var settingsList: some View {
        List(selection: $content) {
            subscriptionSection
            iCloudSection
            notificationSection
            manageSection
            generalSection
            ShortcutsLinkSection()
        }
    }

    var subscriptionSection: some View {
        Section {
            if shouldShowSubscriptionTip {
                TipView(subscriptionTip)
            }
            NavigationLink(value: SettingsContent.subscription) {
                Text("Subscription")
            }
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
            if shouldShowDailySuggestionTip {
                TipView(dailySuggestionTip)
            }
            Toggle("Daily recipe suggestions", isOn: $isDailyRecipeSuggestionNotificationOn)
            if isDailyRecipeSuggestionNotificationOn {
                DatePicker(
                    "Notify time",
                    selection: dailySuggestionTime,
                    displayedComponents: .hourAndMinute
                )
                Button("Send test notification") {
                    Task {
                        await notificationService.sendTestSuggestionNotification()
                    }
                }
                if notificationService.authorizationStatus == .denied {
                    Text("Notifications are disabled in system settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Open Notification Settings") {
                        openNotificationSettings()
                    }
                }
            }
        }
    }

    var manageSection: some View {
        Section {
            Button("Delete All", systemImage: "trash", role: .destructive) {
                isAlertPresented = true
            }
        } header: {
            Text("Manage")
        }
    }

    var generalSection: some View {
        Section {
            NavigationLink(value: SettingsContent.license) {
                Text("Licenses")
            }
            Button("Show tips again") {
                do {
                    try tipController.resetTips()
                    refreshTipEligibility()
                } catch {
                    assertionFailure(error.localizedDescription)
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
        isDailyRecipeSuggestionNotificationOn == false && isDailySuggestionTipEligible
    }

    var shouldShowSubscriptionTip: Bool {
        isSubscribeOn == false && shouldShowDailySuggestionTip == false && isSubscriptionTipEligible
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

    func applyNotificationSettings() {
        Task {
            await settingsActionService.applyNotificationSettings()
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
        isDailySuggestionTipEligible = dailySuggestionTip.shouldDisplay
        isSubscriptionTipEligible = subscriptionTip.shouldDisplay
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        SettingsSidebarView()
    }
}
