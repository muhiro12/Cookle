//
//  CookleIntents.swift
//  Cookle
//
//  Created by Hiromu Nakano on 9/8/24.
//

import SwiftData
import SwiftUI

@MainActor
enum CookleIntents {
    static let modelContainer = try! ModelContainer(
        for: Recipe.self,
        configurations: .init(
            cloudKitDatabase: AppStorage(.isICloudOn).wrappedValue ? .automatic : .none
        )
    )

    static let context = modelContainer.mainContext

    static func cookleView(content: () -> some View) -> some View {
        content()
            .safeAreaPadding()
            .modelContainer(modelContainer)
            .cookleEnvironment(
                googleMobileAds: { _ in EmptyView() },
                licenseList: { EmptyView() },
                storeKit: { EmptyView() },
                appIntents: { EmptyView() }
            )
    }
}
