import SwiftUI

/// Lists recently opened iPhone recipes cached on Watch so cooking can start
/// from Watch, including while iPhone is out of reach.
struct WatchRecentRecipesView: View {
    private enum Layout {
        static let sectionSpacing: CGFloat = 8
    }

    @EnvironmentObject private var cookingSessionStore: WatchCookingSessionStore

    var body: some View {
        if let recipes = cookingSessionStore.recentRecipeCatalog?.recipes,
           recipes.isEmpty == false {
            List {
                Section {
                    ForEach(recipes) { recipe in
                        Button {
                            cookingSessionStore.startSession(for: recipe)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(verbatim: recipe.title)
                                    .font(.headline)
                                Text("\(recipe.steps.count) steps")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Recently Opened on iPhone")
                } footer: {
                    Text("Copies saved from iPhone. Recent edits appear when iPhone is nearby.")
                }
                WatchCookingSyncNotice()
            }
        } else {
            ScrollView {
                VStack(spacing: Layout.sectionSpacing) {
                    Image(systemName: "iphone")
                        .font(.title2)
                        .accessibilityHidden(true)
                    Text("Start on iPhone")
                        .font(.headline)
                    Text(
                        "Begin an active cooking session in Cookle on your iPhone."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    Text("Recipes you open on iPhone appear here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    WatchCookingSyncNotice()
                }
                .padding()
            }
        }
    }
}
