//
//  MainView.swift
//
//
//  Created by Hiromu Nakano on 2024/05/27.
//

import SwiftData
import SwiftUI

struct MainView: View {
    @AppStorage(.isICloudOn) private var isICloudOn

    private var sharedModelContainer: ModelContainer!

    init() {
        sharedModelContainer = try! .init(
            for: Recipe.self,
            configurations: .init(
                cloudKitDatabase: isICloudOn ? .automatic : .none
            )
        )
    }

    var body: some View {
        MainNavigationView()
            .modelContainer(sharedModelContainer)
            .id(isICloudOn)
    }
}

#Preview {
    CooklePreview { _ in
        MainView()
    }
}
