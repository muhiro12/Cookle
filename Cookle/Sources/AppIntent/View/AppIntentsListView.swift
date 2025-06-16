//
//  AppIntentsListView.swift
//  Cookle Playgrounds
//
//  Created by Codex on $(date +%Y/%m/%d).
//

import SwiftData
import SwiftUI

struct AppIntentsListView: View {
    @State private var destination: Destination?

    enum Destination: Hashable {
        case search([Recipe])
        case recipe(Recipe)
    }

    var body: some View {
        List {
            ForEach(Array(CookleShortcuts.appShortcuts.enumerated()), id: \._offset) { index, shortcut in
                Button {
                    run(shortcut)
                } label: {
                    Label(shortcut.shortTitle ?? "Shortcut", systemImage: shortcut.systemImageName)
                }
            }
        }
        .navigationTitle(Text("Shortcuts"))
        .navigationDestination(for: Destination.self) { destination in
            switch destination {
            case let .search(recipes):
                ScrollView {
                    ForEach(recipes) { recipe in
                        VStack(alignment: .leading) {
                            Text(recipe.name)
                                .font(.headline)
                            if let photo = recipe.photoObjects?.min()?.photo,
                               let image = UIImage(data: photo.data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 240)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(.rect(cornerRadius: 8))
                            }
                            RecipeIngredientsSection()
                            Divider()
                        }
                        .environment(recipe)
                    }
                }
                .safeAreaPadding()
            case let .recipe(recipe):
                VStack(alignment: .leading) {
                    if let photo = recipe.photoObjects?.min()?.photo,
                       let image = UIImage(data: photo.data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 240)
                            .frame(maxWidth: .infinity)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    RecipeIngredientsSection()
                    Divider()
                    RecipeStepsSection()
                }
                .environment(recipe)
                .safeAreaPadding()
            }
        }
    }

    private func run(_ shortcut: AppShortcut) {
        Task { @MainActor in
            switch shortcut.intent {
            case is OpenCookleIntent:
                break
            case is ShowSearchResultIntent:
                if let result = try? ShowSearchResultIntent.perform(searchText: "") {
                    destination = .search(result)
                }
            case is ShowLastOpenedRecipeIntent:
                if let recipe = try? ShowLastOpenedRecipeIntent.perform(id: AppStorage(.lastOpenedRecipeID).wrappedValue) {
                    if let recipe {
                        destination = .recipe(recipe)
                    }
                }
            case is ShowRandomRecipeIntent:
                if let recipe = try? ShowRandomRecipeIntent.perform() {
                    if let recipe {
                        destination = .recipe(recipe)
                    }
                }
            default:
                break
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            AppIntentsListView()
        }
    }
}
