//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase)
    private var scenePhase
    @Environment(NotificationService.self)
    private var notificationService
    @State private var hasSkippedInitialActiveNotificationSync = false

    var body: some View {
        MainView()
            .task {
                await notificationService.synchronizeScheduledSuggestions()
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else {
                    return
                }
                guard hasSkippedInitialActiveNotificationSync else {
                    hasSkippedInitialActiveNotificationSync = true
                    return
                }
                Task {
                    await notificationService.synchronizeScheduledSuggestions()
                }
            }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    ContentView()
}
