import CookleLibrary
import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormNavigationView: View {
    private let source: RecipeImportSource
    @State private var websiteSource: RecipeWebsiteSource?
    @State private var sourceURL: URL?
    @State private var photoData: Data?
    private let model: RecipeFormModel

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
                model: model,
                source: source,
                initialWebsiteSource: websiteSource,
                initialSourceURL: sourceURL,
                initialPhotoData: photoData,
                choosesAnotherPhoto: photoData == nil ? nil : {
                    photoData = nil
                }
            )
        }
    }

    init(
        model: RecipeFormModel,
        source: RecipeImportSource
    ) {
        self.model = model
        self.source = source
    }
}
