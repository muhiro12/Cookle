import MHPlatform
import MHUI
import SwiftData
import SwiftUI
import TipKit
import UIKit

struct SettingsSidebarView: View {
    private let model: SettingsScreenModel

    @Environment(\.cookleSplitSidebarBackground)
    private var sidebarBackground

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
    @AppStorage(\.recipeSuggestionNotificationMode, default: "adaptive")
    private var suggestionMode

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
                    if isPresented {
                        CloseButton()
                    }
                }
            }
            .settingsDataManagementDialogs(
                model: model,
                modelContainer: context.container,
                settingsActionService: settingsActionService,
                isICloudEnabled: context.container.isICloudSyncEnabled
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
            .onChange(of: suggestionMode) {
                refreshTipEligibility()
            }
            .onChange(of: isSubscribeOn) {
                refreshTipEligibility()
            }
            .onChange(of: content) {
                if content == .subscription {
                    tipController.donateDidOpenSubscription()
                }
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
            SettingsDataManagementSection(
                model: model,
                modelContainer: context.container,
                settingsActionService: settingsActionService,
                isICloudEnabled: context.container.isICloudSyncEnabled
            )
            generalSection
            ShortcutsLinkSection(
                tip: currentSettingsTip(
                    for: shortcutsTip,
                    isEligible: shouldShowShortcutsTip
                )
            )
        }
        // A custom row background obscures the system's selected-row fill.
        .mhListChrome(.native, background: sidebarBackground)
    }

    @ViewBuilder var subscriptionSection: some View {
        if !isSubscribeOn {
            Section {
                NavigationLink(value: SettingsContent.subscription) {
                    Text("Subscription")
                }
                .cooklePopoverTip(
                    currentSettingsTip(
                        for: subscriptionTip,
                        isEligible: shouldShowSubscriptionTip
                    ),
                    arrowEdge: .top
                )
            }
        }
    }

    @ViewBuilder var iCloudSection: some View {
        #if DEBUG
        Section {
            Text("Development data stays on this device.")
        }
        #else
        SettingsICloudSection(
            isICloudOn: $isICloudOn,
            isSubscriptionActive: isSubscribeOn,
            isICloudConfigured: context.container.isICloudSyncEnabled
        )
        #endif
    }

    var notificationSection: some View {
        SettingsRecipeSuggestionsSection(
            model: model,
            tip: currentSettingsTip(
                for: dailySuggestionTip,
                isEligible: shouldShowDailySuggestionTip
            )
        )
    }

    var generalSection: some View {
        Section {
            NavigationLink(value: SettingsContent.advanced) {
                Text("Advanced")
            }
            NavigationLink(value: SettingsContent.license) {
                Text("Licenses")
            }
            AdsPrivacyOptionsButton { message in
                model.errorMessage = message
            }
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

    init(
        model: SettingsScreenModel,
        selection: Binding<SettingsContent?> = .constant(nil)
    ) {
        self.model = model
        self._content = selection
    }
}

private extension SettingsSidebarView {
    var shouldShowDailySuggestionTip: Bool {
        suggestionMode == RecipeSuggestionNotificationMode.off.rawValue && model.isDailySuggestionTipEligible
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
        SettingsSidebarView(model: .init())
    }
}
