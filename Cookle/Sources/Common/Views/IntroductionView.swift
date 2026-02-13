//
//  IntroductionView.swift
//  Cookle
//
//  Created by Codex on 2026/02/14.
//

import SwiftData
import SwiftUI

struct IntroductionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPageIndex: Int = .zero

    @Query(.recipes(.all)) private var recipes: [Recipe]
    @Query(.diaries(.all)) private var diaries: [Diary]

    var body: some View {
        VStack(spacing: .zero) {
            TabView(selection: $selectedPageIndex) {
                contentPage {
                    VStack(spacing: 16) {
                        Image(systemName: "book.pages.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 120)
                            .foregroundStyle(.tint)
                            .padding(.top, 8)
                        Text("Welcome to Cookle")
                            .font(.title2)
                            .bold()
                        Text("Save recipes, plan daily meals, and find what to cook faster.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .tag(0)

                contentPage {
                    VStack(spacing: 16) {
                        Label("Save recipes quickly", systemImage: "list.bullet")
                            .font(.title3)
                            .bold()
                        recipeListSample()
                    }
                }
                .tag(1)

                contentPage {
                    VStack(spacing: 16) {
                        Label("See recipe details at a glance", systemImage: "doc.text.magnifyingglass")
                            .font(.title3)
                            .bold()
                        recipeDetailSample()
                    }
                }
                .tag(2)

                contentPage {
                    VStack(spacing: 16) {
                        Label("Plan meals with diaries", systemImage: "calendar")
                            .font(.title3)
                            .bold()
                        diaryListSample()
                    }
                }
                .tag(3)

                contentPage {
                    VStack(spacing: 16) {
                        Label("Daily suggestions & Premium", systemImage: "bell.badge")
                            .font(.title3)
                            .bold()
                        suggestionAndPremiumSample()
                    }
                }
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            HStack(spacing: 8) {
                Button {
                    dismiss()
                } label: {
                    Label("Skip for Now", systemImage: "forward.end")
                }
                .buttonStyle(.borderless)

                Spacer(minLength: .zero)

                Button {
                    dismiss()
                } label: {
                    Text("Start Cooking")
                        .bold()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle(Text("Welcome"))
        .toolbar {
            ToolbarItem {
                CloseButton()
            }
        }
        .interactiveDismissDisabled()
        .task {
            seedTutorialDataIfNeeded()
        }
    }
}

private extension IntroductionView {
    func seedTutorialDataIfNeeded() {
        do {
            try IntroductionTutorialSeeder.seed(context: context)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func contentPage<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack {
            content()
                .padding(.vertical, 8)
                .padding(.horizontal)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(Color(uiColor: .secondarySystemBackground))
    }

    func recipeListSample() -> some View {
        List {
            ForEach(Array(recipes.prefix(5))) { recipe in
                RecipeLabel()
                    .environment(recipe)
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .allowsHitTesting(false)
    }

    func recipeDetailSample() -> some View {
        List {
            if let recipe = recipes.first {
                Section("Ingredients") {
                    let sortedIngredients = recipe.ingredientObjects.orEmpty.sorted()
                    ForEach(Array(sortedIngredients.prefix(3))) { ingredientObject in
                        HStack {
                            Text(ingredientObject.ingredient?.value ?? "Ingredient")
                            Spacer()
                            Text(ingredientObject.amount)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Steps") {
                    let sampleSteps = Array(recipe.steps.prefix(3))
                    ForEach(sampleSteps.indices, id: \.self) { index in
                        Label {
                            Text(sampleSteps[index])
                        } icon: {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDisabled(true)
        .allowsHitTesting(false)
    }

    func diaryListSample() -> some View {
        List {
            ForEach(Array(diaries.prefix(3))) { diary in
                DiaryLabel()
                    .environment(diary)
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .allowsHitTesting(false)
    }

    func suggestionAndPremiumSample() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily random recipe suggestions")
                .font(.headline)
            Text("Enable them in Settings to receive a random recipe at your chosen time each day.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Premium options")
                .font(.headline)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 6) {
                Label("Sync data with iCloud", systemImage: "icloud")
                Label("Remove ads across the app", systemImage: "rectangle.badge.xmark")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.1))
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    IntroductionView()
}
