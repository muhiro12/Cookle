//
//  DiaryFormNavigationView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/17.
//

import SwiftUI
import SwiftData

struct DiaryFormNavigationView: View {
    enum DiaryType {
        case breakfast
        case lunch
        case dinner
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Environment(Diary.self) private var diary: Diary?

    @Query(Recipe.descriptor) private var recipes: [Recipe]

    @State private var date = Date.now
    @State private var breakfasts = Set<Recipe>()
    @State private var lunches = Set<Recipe>()
    @State private var dinners = Set<Recipe>()
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
                        guard breakfasts.contains($0) else {
                            return nil
                        }
                        return $0.name
                    }.joined(separator: ", "))
                }
                Section {
                    NavigationLink("Lunch", value: DiaryType.lunch)
                } footer: {
                    Text(recipes.compactMap {
                        guard lunches.contains($0) else {
                            return nil
                        }
                        return $0.name
                    }.joined(separator: ", "))
                }
                Section {
                    NavigationLink("Dinner", value: DiaryType.dinner)
                } footer: {
                    Text(recipes.compactMap {
                        guard dinners.contains($0) else {
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
                    id: \.self,
                    selection: {
                        switch type {
                        case .breakfast:
                            $breakfasts
                        case .lunch:
                            $lunches
                        case .dinner:
                            $dinners
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
                ToolbarItem(placement: .confirmationAction) {
                    Button(diary != nil ? "Update" : "Add") {
                        if let diary {
                            diary.update(
                                date: date,
                                breakfasts: .init(breakfasts),
                                lunches: .init(lunches),
                                dinners: .init(dinners)
                            )
                        } else {
                            _ = Diary.create(
                                context: context,
                                date: date,
                                breakfasts: .init(breakfasts),
                                lunches: .init(lunches),
                                dinners: .init(dinners)
                            )
                        }
                        dismiss()
                    }
                    .disabled(breakfasts.isEmpty && lunches.isEmpty && dinners.isEmpty)
                }
            }
        }
        .task {
            date = diary?.date ?? .now
            breakfasts = .init(diary?.breakfasts ?? [])
            lunches = .init(diary?.lunches ?? [])
            dinners = .init(diary?.dinners ?? [])
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    ModelContainerPreview { _ in
        DiaryFormNavigationView()
    }
}
