// import SwiftUI
//
// @available(iOS 26.0, *)
// struct InferRecipeFormButton: View {
//    @Binding private var name: String
//    @Binding private var servingSize: String
//    @Binding private var cookingTime: String
//    @Binding private var ingredients: [RecipeFormIngredient]
//    @Binding private var steps: [String]
//    @Binding private var categories: [String]
//    @Binding private var note: String
//
//    @State private var isPresented = false
//
//    init(name: Binding<String>,
//         servingSize: Binding<String>,
//         cookingTime: Binding<String>,
//         ingredients: Binding<[RecipeFormIngredient]>,
//         steps: Binding<[String]>,
//         categories: Binding<[String]>,
//         note: Binding<String>) {
//        self._name = name
//        self._servingSize = servingSize
//        self._cookingTime = cookingTime
//        self._ingredients = ingredients
//        self._steps = steps
//        self._categories = categories
//        self._note = note
//    }
//
//    var body: some View {
//        Button {
//            isPresented = true
//        } label: {
//            Text("Infer Recipe From Text")
//        }
//        .sheet(isPresented: $isPresented) {
//            InferRecipeFormNavigationView(
//                name: $name,
//                servingSize: $servingSize,
//                cookingTime: $cookingTime,
//                ingredients: $ingredients,
//                steps: $steps,
//                categories: $categories,
//                note: $note
//            )
//            .interactiveDismissDisabled()
//        }
//    }
// }
