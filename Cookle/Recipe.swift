//
//  Recipe.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/08.
//

import Foundation
import SwiftData

@Model
final class Recipe {
    private(set) var name: String
    private(set) var summary: String
    private(set) var tag: String
    private(set) var ingredients: [String]
    private(set) var instructions: [String]
    private(set) var image: Data?
    private(set) var creationDate: Date
    private(set) var updateDate: Date

    init() {
        self.name = Self.randomWords(1)
        self.summary = Self.randomWords(20)
        self.tag = Self.randomWords(1)
        self.ingredients = (0...Int.random(in: 0..<20)).map { _ in Self.randomWords(1) }
        self.instructions = (0...Int.random(in: 0..<20)).map { _ in Self.randomWords(Int.random(in: 5...10)) }
        self.image = nil
        self.creationDate = .now
        self.updateDate = .now
    }

    var year: String {
        updateDate.formatted(date: .numeric, time: .omitted)
    }

    var yearMonth: String {
        updateDate.formatted(date: .omitted, time: .shortened)
    }

    private static let cookingWords = [
        "Chicken", "Beef", "Pork", "Salmon", "Tuna", "Shrimp", "Tofu", "Eggplant", "Zucchini",
        "Tomato", "Basil", "Cilantro", "Parsley", "Thyme", "Rosemary", "Sage", "Oregano", "Pepper",
        "Salt", "Paprika", "Cumin", "Chili", "Turmeric", "Ginger", "Garlic", "Onion", "Lemon", "Lime",
        "Vinegar", "Soy Sauce", "Sesame Oil", "Olive Oil", "Butter", "Milk", "Cream", "Cheese", "Yogurt",
        "Pasta", "Rice", "Quinoa", "Barley", "Bread", "Pastry", "Cake", "Cookie", "Pie", "Chocolate",
        "Vanilla", "Cinnamon", "Nutmeg", "Cloves", "Sugar", "Honey", "Maple Syrup", "Beet", "Carrot",
        "Potato", "Sweet Potato", "Radish", "Cucumber", "Bell Pepper", "Chili Pepper", "Jalapeno", "Mushroom",
        "Broccoli", "Cauliflower", "Cabbage", "Kale", "Lettuce", "Spinach", "Corn", "Peas", "Green Bean",
        "Apple", "Banana", "Orange", "Berry", "Melon", "Grape", "Peach", "Plum", "Cherry", "Almond",
        "Peanut", "Walnut", "Cashew", "Pistachio", "Oatmeal", "Granola", "Hamburger", "Pizza", "Sandwich",
        "Soup", "Stew", "Curry", "Sauce", "Dressing", "Marinade", "Grill", "Roast", "Bake", "Fry",
        "Steam", "Boil", "Simmer", "Sauté", "Chop", "Slice", "Dice", "Mince", "Blend", "Whisk",
        "Knead", "Roll", "Ferment", "Season", "Garnish", "Plate", "Serve", "Enjoy", "Delicious", "Tasty",
        "Savory", "Sweet", "Spicy", "Tangy", "Rich", "Creamy", "Crunchy", "Crispy", "Smooth", "Soft",
        "Juicy", "Moist", "Tender", "Fluffy", "Light", "Heavy", "Dense", "Hearty", "Warm", "Cool",
        "Cold", "Refreshing", "Satisfying", "Comforting", "Gourmet", "Traditional", "Modern", "Innovative",
        "Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Nut-Free", "Low-Carb", "Keto", "Paleo"
    ]

    private static func randomWords(_ length: Int) -> String {
        var words = ""
        for _ in 0..<length {
            words += " " + cookingWords[Int.random(in: 0..<cookingWords.endIndex)]
        }
        return words.dropFirst().description
    }
}
