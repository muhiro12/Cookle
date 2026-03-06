//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import MHPlatform
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(MHAppRuntime.self)
    private var appRuntime
    @Environment(NotificationService.self)
    private var notificationService

    @AppStorage(.isSubscribeOn)
    private var isSubscribeOn
    @AppStorage(.isICloudOn)
    private var isICloudOn

    @State private var hasSkippedInitialActiveNotificationSync = false

    var body: some View {
        MainView()
            .task {
                appRuntime.startIfNeeded()
                syncSubscriptionStateIfNeeded()
                await notificationService.synchronizeScheduledSuggestions()
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else {
                    return
                }
                appRuntime.startIfNeeded()
                syncSubscriptionStateIfNeeded()
                guard hasSkippedInitialActiveNotificationSync else {
                    hasSkippedInitialActiveNotificationSync = true
                    return
                }
                Task {
                    await notificationService.synchronizeScheduledSuggestions()
                }
            }
            .onChange(of: appRuntime.premiumStatus) {
                syncSubscriptionStateIfNeeded()
            }
    }
}

@MainActor
private extension ContentView {
    func syncSubscriptionStateIfNeeded() {
        switch appRuntime.premiumStatus {
        case .unknown:
            return
        case .inactive:
            isSubscribeOn = false
            isICloudOn = false
        case .active:
            isSubscribeOn = true
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    ContentView()
}
