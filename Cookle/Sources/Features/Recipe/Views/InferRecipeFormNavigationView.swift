import CookleLibrary
import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormNavigationView: View {
    private let source: RecipeImportSource
    @State private var websiteSource: RecipeWebsiteSource?
    @State private var sourceURL: URL?
    @State private var photoData: Data?
    @Binding var name: String
    @Binding var servingSize: String
    @Binding var cookingTime: String
    @Binding var ingredients: [RecipeFormIngredient]
    @Binding var steps: [String]
    @Binding var categories: [String]
    @Binding var note: String

    var body: some View {
        if source == .website, websiteSource == nil {
            RecipeWebsiteImportView(dismissAfterImport: false) { importedSource, url in
                websiteSource = importedSource
                sourceURL = url
            }
        } else if source == .photo, photoData == nil {
            RecipePhotoTextImportView { data in
                photoData = data
            }
        } else {
            reviewNavigation
        }
    }

    private var reviewNavigation: some View {
        NavigationStack {
            InferRecipeFormView(
                name: $name,
                servingSize: $servingSize,
                cookingTime: $cookingTime,
                ingredients: $ingredients,
                steps: $steps,
                categories: $categories,
                note: $note,
                source: source,
                initialWebsiteSource: websiteSource,
                initialSourceURL: sourceURL,
                initialPhotoData: photoData
            )
        }
    }

    init(name: Binding<String>,
         servingSize: Binding<String>,
         cookingTime: Binding<String>,
         ingredients: Binding<[RecipeFormIngredient]>,
         steps: Binding<[String]>,
         categories: Binding<[String]>,
         note: Binding<String>,
         source: RecipeImportSource) {
        self.source = source
        self._name = name
        self._servingSize = servingSize
        self._cookingTime = cookingTime
        self._ingredients = ingredients
        self._steps = steps
        self._categories = categories
        self._note = note
    }
}
