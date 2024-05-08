//
//  DiaryFormRootView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/17.
//

import SwiftUI
import SwiftData

struct DiaryFormRootView: View {
    enum DiaryType {
        case breakfast
        case lunch
        case dinner
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var recipes: [Recipe]

    @State private var date = Date.now
    @State private var breakfasts = Set<Recipe.ID>()
    @State private var lunches = Set<Recipe.ID>()
    @State private var dinners = Set<Recipe.ID>()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                Section {
                    NavigationLink("Breakfast", value: DiaryType.breakfast)
                } footer: {
                    Text(recipes.compactMap {
                        guard breakfasts.contains($0.id) else {
                            return nil
                        }
                        return $0.name
                    }.joined(separator: ", "))
                }
                Section {
                    NavigationLink("Lunch", value: DiaryType.lunch)
                } footer: {
                    Text(recipes.compactMap {
                        guard lunches.contains($0.id) else {
                            return nil
                        }
                        return $0.name
                    }.joined(separator: ", "))
                }
                Section {
                    NavigationLink("Dinner", value: DiaryType.dinner)
                } footer: {
                    Text(recipes.compactMap {
                        guard dinners.contains($0.id) else {
                            return nil
                        }
                        return $0.name
                    }.joined(separator: ", "))
                }
            }
            .navigationDestination(for: DiaryType.self) { type in
                List(
                    recipes.filter {
                        guard !searchText.isEmpty else {
                            return true
                        }
                        return $0.name.lowercased().contains(searchText.lowercased())
                    },
                    id: \.id,
                    selection: {
                        switch type {
                        case .breakfast:
                            return $breakfasts
                        case .lunch:
                            return $lunches
                        case .dinner:
                            return $dinners
                        }
                    }()
                ) { recipe in
                    Text(recipe.name)
                }
                .searchable(text: $searchText)
                .environment(\.editMode, .constant(.active))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem {
                    Button("Add") {
                        _ = Diary.create(
                            context: context,
                            date: date,
                            breakfasts: recipes.filter { breakfasts.contains($0.id) },
                            lunches: recipes.filter { lunches.contains($0.id) },
                            dinners: recipes.filter { dinners.contains($0.id) }
                        )
                        dismiss()
                    }
                    .disabled(breakfasts.isEmpty && lunches.isEmpty && dinners.isEmpty)
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    ModelContainerPreview { _ in
        DiaryFormRootView()
    }
}
