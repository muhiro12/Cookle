//
//  MainView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/27.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    @AppStorage(.isICloudOn) private var isICloudOn

    private var sharedModelContainer: ModelContainer!

    init() {
        sharedModelContainer = try! .init(
            for: .init(versionedSchema: CookleMigrationPlan.schemas[0]),
            migrationPlan: CookleMigrationPlan.self,
            configurations: .init(
                cloudKitDatabase: isICloudOn ? .automatic : .none
            )
        )
    }

    var body: some View {
        MainTabView()
            .onChange(of: scenePhase) {
                guard scenePhase == .active else {
                    return
                }
                if Int.random(in: 0..<10) == .zero {
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        requestReview()
                    }
                }
            }
            .modelContainer(sharedModelContainer)
            .id(isICloudOn)
    }
}

#Preview {
    CooklePreview { _ in
        MainView()
    }
}
