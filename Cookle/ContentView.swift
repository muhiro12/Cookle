//
//  ContentView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(NotificationService.self) private var notificationService

    init() {}

    var body: some View {
        MainView()
            .onAppear {
                Logger(#file).info("ContentView appeared")
            }
            .task {
                await notificationService.synchronizeScheduledSuggestions()
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else {
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
