//
//  ModelContainerPreview.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct ModelContainerPreview<Content: View>: View {
    let content: (Self) -> Content

    @State private(set) var diaries = [Diary]()
    @State private(set) var recipes = [Recipe]()
    @State private(set) var ingredientObjects = [IngredientObject]()
    @State private(set) var ingredients = [Ingredient]()
    @State private(set) var categories = [Category]()
    @State private var isReady = false

    private let previewModelContainer = try! ModelContainer(for: Recipe.self, configurations: .init(isStoredInMemoryOnly: true))

    var body: some View {
        if isReady {
            content(self)
                .modelContainer(previewModelContainer)
        } else {
            ProgressView()
                .task {
                    let context = previewModelContainer.mainContext
                    (0..<20).forEach { _ in
                        _ = randomDiary(context)
                    }
                    repeat {
                        try! await Task.sleep(for: .seconds(0.2))
                        diaries = try! context.fetch(.init())
                        recipes = try! context.fetch(.init())
                        ingredientObjects = try! context.fetch(.init())
                        ingredients = try! context.fetch(.init())
                        categories = try! context.fetch(.init())
                    } while diaries.isEmpty || recipes.isEmpty || ingredientObjects.isEmpty || ingredients.isEmpty || categories.isEmpty
                    isReady = true
                }
        }
    }

    func randomDiary(_ context: ModelContext) -> Diary {
        var recipes = [Recipe]()
        (0..<6).forEach { _ in
            let recipe = randomRecipe(context)
            recipes.append(recipe)
        }
        return .create(
            context: context,
            date: .now.addingTimeInterval(.random(in: 0...(60 * 60 * 24 * 365 * 2))),
            breakfasts: [recipes[0]],
            lunches: [recipes[1],
                      recipes[2]],
            dinners: [recipes[3],
                      recipes[4],
                      recipes[5]]
        )
    }

    private func randomRecipe(_ context: ModelContext) -> Recipe {
        .create(
            context: context,
            name: randomWords(from: nameStrings),
            servingSize: Int.random(in: 1...6),
            cookingTime: Int.random(in: 5...60),
            ingredients: (0...Int.random(in: 0..<20)).map { _ in
                    .create(context: context,
                            ingredient: randomWords(from: ingredientStrings),
                            amount: randomWords(from: amountStrings))
            },
            steps: (0...Int.random(in: 0..<20)).map { _ in
                randomWords(from: stepStrings)
            },
            categories: (0...Int.random(in: 0..<5)).map { _ in
                    .create(context: context,
                            value: randomWords(from: categoryStrings))
            }
        )
    }

    private func randomWords(from list: [String], length: Int = 1) -> String {
        var words = ""
        for _ in 0..<length {
            words += " " + list[Int.random(in: 0..<list.endIndex)]
        }
        return words.dropFirst().description
    }

    private let nameStrings = [
        "Grilled Salmon", "Chicken Parmesan", "Vegetable Stir Fry", "Beef Stroganoff", "Spaghetti Carbonara",
        "Lamb Curry", "Shrimp Paella", "Pork Schnitzel", "Ratatouille", "Duck Confit",
        "Mushroom Risotto", "Quiche Lorraine", "Fish and Chips", "Sushi Rolls", "Tom Yum Soup",
        "BBQ Ribs", "Falafel Wrap", "Beef Tacos", "Margherita Pizza", "Caesar Salad",
        "Pad Thai", "Chicken Tikka Masala", "Beef Bourguignon", "Ramen Noodles", "Spinach Lasagna",
        "Cobb Salad", "Peking Duck", "Pho", "Fettuccine Alfredo", "Jambalaya",
        "Coq au Vin", "Carnitas", "Moussaka", "Gazpacho", "Bibimbap",
        "Tandoori Chicken", "French Onion Soup", "Seafood Gumbo", "Pastrami Sandwich", "Clam Chowder",
        "Roast Beef", "Pasta Primavera", "Veal Piccata", "Greek Salad", "Pan-Seared Tuna",
        "Eggplant Parmigiana", "Croque Monsieur", "Chicken Caesar Wrap", "Lobster Bisque", "Shepherd's Pie",
        "Corned Beef Hash", "Chicken Alfredo", "Beef Enchiladas", "Chili Con Carne", "Caprese Salad",
        "Mapo Tofu", "Bangers and Mash", "Turkey Club Sandwich", "Butternut Squash Soup", "Chicken Marsala",
        "Pot Roast", "Vegetable Curry", "Salmon Tartare", "Pulled Pork Sandwich", "Beef Wellington",
        "Minestrone Soup", "Baked Ziti", "Chicken Fajitas", "Vegetable Quiche", "Pasta Bolognese",
        "Tuna Nicoise Salad", "Pork Belly Bao", "French Toast", "Vegetarian Chili", "Beef Barbacoa",
        "Shakshuka", "Avocado Toast", "Kimchi Stew", "Szechuan Beef", "Roasted Brussels Sprouts",
        "Margherita Flatbread", "Lentil Soup", "Buffalo Wings", "Chicken and Waffles", "Miso Soup",
        "Nachos Supreme", "Egg Benedicts", "Vegetable Samosas", "Spicy Tuna Roll", "Margarita Flatbread",
        "Tomato Bruschetta", "Ceviche", "Fried Chicken", "Gnocchi", "Escargot",
        "Huevos Rancheros", "Baked Cod", "Risotto Milanese", "Chicken Quesadilla", "Vegetable Paella"
    ]

    private let ingredientStrings = [
        "Chicken Breast", "Salmon Fillet", "Ground Beef", "Pork Loin", "Tofu",
        "Shrimp", "Scallops", "Mussels", "Eggplant", "Zucchini",
        "Bell Pepper", "Spinach", "Kale", "Arugula", "Butternut Squash",
        "Sweet Potato", "Carrots", "Beets", "Onions", "Garlic",
        "Ginger", "Tomatoes", "Cucumbers", "Avocado", "Apples",
        "Bananas", "Blueberries", "Strawberries", "Oranges", "Lemons",
        "Limes", "Pineapple", "Mango", "Peaches", "Plums",
        "Almonds", "Walnuts", "Pecans", "Cashews", "Peanuts",
        "Quinoa", "Rice", "Pasta", "Bread", "Flour",
        "Sugar", "Honey", "Maple Syrup", "Olive Oil", "Coconut Oil",
        "Butter", "Milk", "Cream", "Yogurt", "Cheese",
        "Eggs", "Basil", "Parsley", "Cilantro", "Dill",
        "Rosemary", "Thyme", "Oregano", "Cumin", "Paprika",
        "Chili Powder", "Curry Powder", "Soy Sauce", "Fish Sauce", "Vinegar",
        "Mustard", "Ketchup", "Mayonnaise", "Salsa", "Tomato Paste",
        "Chicken Stock", "Beef Broth", "Vegetable Stock", "Coconut Milk", "Almond Milk",
        "Rice Vinegar", "Sesame Oil", "Sunflower Seeds", "Pumpkin Seeds", "Chia Seeds",
        "Lentils", "Chickpeas", "Black Beans", "Kidney Beans", "Navy Beans",
        "Broccoli", "Cauliflower", "Asparagus", "Green Beans", "Peas",
        "Corn", "Mushrooms", "Potatoes", "Cabbage", "Brussels Sprouts"
    ]

    private let amountStrings = [
        "1 cup", "2 cups", "1/2 cup", "1/4 cup", "3/4 cup",
        "1 tablespoon", "2 tablespoons", "1 teaspoon", "2 teaspoons", "1/2 teaspoon",
        "1/4 teaspoon", "3 tablespoons", "4 tablespoons", "1 pint", "1 quart",
        "1 gallon", "1 liter", "500 ml", "200 ml", "100 ml",
        "50 grams", "100 grams", "200 grams", "500 grams", "1 kilogram",
        "1 pound", "1/2 pound", "1/4 pound", "2 pounds", "3 pounds",
        "1 ounce", "2 ounces", "3 ounces", "4 ounces", "5 ounces",
        "1 pinch", "2 pinches", "a dash", "a smidge", "a slice",
        "2 slices", "3 slices", "4 slices", "a handful", "a small handful",
        "a large handful", "a bunch", "a small bunch", "a large bunch", "a piece",
        "2 pieces", "3 pieces", "1 packet", "1 sachet", "1 can",
        "2 cans", "1 jar", "2 jars", "1 box", "2 boxes",
        "1 bag", "2 bags", "a few", "several", "a dozen",
        "a couple", "a knob", "a dollop", "a splash", "a sprinkle",
        "a sprig", "2 sprigs", "a stalk", "2 stalks", "a clove",
        "2 cloves", "3 cloves", "a bulb", "a leaf", "2 leaves",
        "a slab", "a slice", "a wedge", "a cube", "1 sheet",
        "2 sheets", "1 roll", "2 rolls", "1 stick", "2 sticks",
        "a drizzle", "a glug", "a drop", "a heap", "a scoop",
        "a dusting", "a topping", "a coating", "a layer", "a shaving",
        "a trim", "a zest", "a twist", "a segment", "a fraction"
    ]


    private let stepStrings = [
        "Preheat the oven to 350°F (175°C).", "Rinse the rice under cold water until the water runs clear.",
        "Chop the onions finely.", "Mince the garlic cloves.", "Grate the ginger.",
        "Dice the tomatoes.", "Slice the chicken breast into strips.", "Season the meat with salt and pepper.",
        "Marinate the fish in lemon juice and olive oil for 30 minutes.", "Bring a pot of salted water to a boil.",
        "Simmer the sauce on low heat for 20 minutes.", "Sauté the vegetables in a hot pan with a little oil.",
        "Bake for 25 minutes or until golden brown.", "Grill the steak to your preferred doneness.",
        "Steam the broccoli until tender but still crisp.", "Fry the eggs in a non-stick skillet.",
        "Whisk the eggs and milk together until well combined.", "Knead the dough until smooth and elastic.",
        "Let the dough rise in a warm place until doubled in size.", "Punch down the dough, then shape into loaves.",
        "Brown the meat on all sides in a heavy skillet.", "Deglaze the pan with a splash of wine.",
        "Reduce the sauce until it thickens.", "Cool the cake on a wire rack before icing.",
        "Blend the soup until smooth using an immersion blender.", "Mix the dry ingredients separately from the wet ingredients.",
        "Fold the beaten egg whites into the batter gently.", "Roll out the dough on a floured surface.",
        "Cut the butter into the flour until crumbly.", "Chill the dough for at least an hour before rolling.",
        "Toast the nuts in a dry pan until fragrant.", "Peel and devein the shrimp.", "Soak the beans overnight in cold water.",
        "Drain the pasta and toss with the sauce.", "Layer the lasagna and cover with cheese.",
        "Roast the vegetables with herbs and olive oil.", "Whip the cream until stiff peaks form.",
        "Caramelize the onions over low heat.", "Stuff the turkey, then truss it securely.",
        "Glaze the ham during the last 30 minutes of baking.", "Skim the fat off the top of the broth.",
        "Zest and juice the lemons.", "Beat the butter and sugar until creamy.", "Infuse the milk with vanilla and cinnamon.",
        "Thread the skewers alternating meat and vegetables.", "Chill the dessert until set.",
        "Garnish with fresh herbs before serving.", "Season to taste with salt and pepper.",
        "Serve the soup hot with a dollop of sour cream.", "Arrange the salad greens on a platter.",
        "Toss the salad with the dressing just before serving.", "Warm the tortillas in the oven wrapped in foil.",
        "Fill the tacos with meat, cheese, and salsa.", "Sprinkle grated chocolate over the dessert.",
        "Melt the chocolate in a double boiler.", "Crush the garlic with the side of a knife.",
        "Use a meat thermometer to check for doneness.", "Let the meat rest before slicing.",
        "Thinly slice the beef against the grain.", "Refrigerate the dough to firm up if too sticky.",
        "Seal the edges of the pie crust with egg wash.", "Brush the pastry with egg wash for a golden finish.",
        "Dry the meat with paper towels for better browning.", "Fluff the cooked rice with a fork.",
        "Layer the ingredients in the slow cooker.", "Cook on low for 8 hours or on high for 4 hours.",
        "Puree the sauce in a blender until smooth.", "Strain the soup to achieve a silky texture.",
        "Macerate the strawberries in sugar.", "Soften the gelatin in cold water before use.",
        "Brew the tea for 3-5 minutes.", "Discard the bay leaves before serving.",
        "Refresh the greens in ice water for crispness.", "Score the duck skin to help the fat render.",
        "Render the bacon slowly to release the fat.", "Degrease the pan by discarding excess fat.",
        "Mount the sauce with butter off the heat.", "Bloom the spices in oil to release their flavors.",
        "Temper the eggs by slowly adding hot liquid.", "Quick pickle the vegetables in vinegar and sugar.",
        "Squeeze out excess moisture from the zucchini.", "Rest the batter to prevent tough pancakes.",
        "Dry brine the chicken for juicier results.", "Tenderize the meat with a marinade."
    ]

    private let categoryStrings = [
        "Japanese", "Western", "French", "Italian", "Chinese",
        "Spanish", "Mediterranean", "Mexican", "Thai", "Indian",
        "Vietnamese", "Korean", "Main-Dish", "Side-Dish", "Soup",
        "Salad", "Appetizer", "Dessert", "Snack", "Drink",
        "Breakfast", "Brunch", "Lunch", "Dinner", "Tea-Time",
        "Healthy", "Quick", "Easy", "Comfort", "Gourmet",
        "Vegan", "Vegetarian", "Gluten-Free", "Low-Carb", "High-Protein",
        "Low-Fat", "Organic", "Seasonal", "Local", "Detox",
        "Festive", "Holiday", "Family-Friendly", "Kid-Friendly", "Party",
        "One-Pot", "Slow-Cooked", "Grilled", "Baked", "Fried",
        "Steamed", "Raw", "Spicy", "Sweet", "Sour",
        "Umami", "Savory", "Creamy", "Crunchy", "Smooth",
        "Light", "Hearty", "Rich", "Refreshing", "Exotic",
        "Traditional", "Modern", "Fusion", "Homemade", "Quick-Prep",
        "Make-Ahead", "Freezable", "Low-Calorie", "High-Fiber", "Sugar-Free",
        "Dairy-Free", "Nut-Free", "Egg-Free", "Low-Sodium", "High-Vitamin",
        "High-Mineral", "Energy-Boosting", "Immunity-Boosting", "Anti-Inflammatory", "Antioxidant-Rich",
        "Meal-Prep", "Budget-Friendly", "Luxurious", "Casual", "Fine-Dining",
        "Street-Food", "Pub-Food", "Comfort-Food", "Soul-Food", "Fast-Food"
    ]
}