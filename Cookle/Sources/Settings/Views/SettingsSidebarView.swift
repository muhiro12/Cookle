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
        List(selection: $content) {
            Section {
                if shouldShowSubscriptionTip {
                    TipView(subscriptionTip)
                }
                NavigationLink(value: SettingsContent.subscription) {
                    Text("Subscription")
                }
                .simultaneousGesture(
                    TapGesture().onEnded {
                        tipController.donateDidOpenSubscription()
                    }
                )
            }
            .hidden(isSubscribeOn)
            Section {
                Toggle("iCloud On", isOn: $isICloudOn)
            } header: {
                Text("Settings")
            }
            .hidden(!isSubscribeOn)
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
            Section {
                Button("Delete All", systemImage: "trash", role: .destructive) {
                    isAlertPresented = true
                }
            } header: {
                Text("Manage")
            }
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
            ShortcutsLinkSection()
        }
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
                withAnimation {
                    do {
                        try DataResetService.deleteAll(context: context)
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
            } label: {
                Text("Delete")
            }
            Button(role: .cancel) {
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Are you sure you want to delete all data?")
        }
        .task {
            normalizeSuggestionTimeDefaultsIfNeeded()
            await notificationService.refreshAuthorizationStatus()
            await notificationService.synchronizeScheduledSuggestions()
            refreshTipEligibility()
        }
        .onChange(of: isDailyRecipeSuggestionNotificationOn) {
            refreshTipEligibility()
            Task {
                await notificationService.applySuggestionSettings()
            }
        }
        .onChange(of: dailyRecipeSuggestionHour) {
            Task {
                await notificationService.applySuggestionSettings()
            }
        }
        .onChange(of: dailyRecipeSuggestionMinute) {
            Task {
                await notificationService.applySuggestionSettings()
            }
        }
        .onChange(of: isSubscribeOn) {
            refreshTipEligibility()
        }
        .onAppear {
            refreshTipEligibility()
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
            let clampedHour = min(max(dailyRecipeSuggestionHour, 0), 23)
            let clampedMinute = min(max(dailyRecipeSuggestionMinute, 0), 59)
            return Calendar.current.date(
                bySettingHour: clampedHour,
                minute: clampedMinute,
                second: 0,
                of: .now
            ) ?? .now
        } set: { newValue in
            dailyRecipeSuggestionHour = Calendar.current.component(.hour, from: newValue)
            dailyRecipeSuggestionMinute = Calendar.current.component(.minute, from: newValue)
        }
    }

    func normalizeSuggestionTimeDefaultsIfNeeded() {
        if UserDefaults.standard.object(forKey: IntPreferenceKey.dailyRecipeSuggestionHour.rawValue) == nil {
            dailyRecipeSuggestionHour = 20
        }
        if UserDefaults.standard.object(forKey: IntPreferenceKey.dailyRecipeSuggestionMinute.rawValue) == nil {
            dailyRecipeSuggestionMinute = 0
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

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        SettingsSidebarView()
    }
}
