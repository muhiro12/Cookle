import SwiftUI

struct RecipeFormPhotoThumbnailView: View {
    let photo: PhotoData
    let index: Int
    let height: CGFloat
    let cornerRadius: CGFloat
    let actionButtonPadding: CGFloat
    let photoRemovalBehavior: RecipePhotoRemovalBehavior?
    @Binding var pendingPhotoRemovalIndex: Int?
    @Binding var isPhotoRemovalDialogPresented: Bool

    var body: some View {
        if let image = UIImage(data: photo.data) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text("Selected Photo"))
                    .frame(height: height)
                    .clipShape(.rect(cornerRadius: cornerRadius))
                photoRemovalMenu
            }
        }
    }

    @ViewBuilder var photoRemovalMenu: some View {
        if photoRemovalBehavior != nil {
            Menu {
                Button(role: .destructive) {
                    pendingPhotoRemovalIndex = index
                    isPhotoRemovalDialogPresented = true
                } label: {
                    Label(
                        "Remove from Recipe",
                        systemImage: "link.badge.minus"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .padding(actionButtonPadding)
                    .background(.thinMaterial, in: .circle)
            }
            .accessibilityLabel(Text("Photo Actions"))
            .padding(actionButtonPadding)
        }
    }
}
