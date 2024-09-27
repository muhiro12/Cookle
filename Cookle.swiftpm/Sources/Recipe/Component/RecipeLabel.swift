import SwiftUI

struct RecipeLabel: View {
    @Environment(Recipe.self) private var recipe
    
    var body: some View {
        Label {
            Text(recipe.name)
        } icon: {
            if let data = recipe.photos?.first?.data,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeLabel()
                .environment(preview.recipes[0])
        }
    }
}
