import SwiftUI

struct RecipeFormPhotoThumbnailView: View {
    let photo: PhotoData
    let photoID: UUID
    let index: Int
    let height: CGFloat
    let cornerRadius: CGFloat
    let actionButtonPadding: CGFloat
    let photoRemovalBehavior: RecipePhotoRemovalBehavior?
    @Binding var pendingPhotoRemovalIndex: Int?
    @Binding var isPhotoRemovalDialogPresented: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CooklePhotoImage(
                data: photo.data,
                identity: .draft(photoID),
                size: .thumbnail
            )
            .accessibilityLabel(Text("Selected Photo"))
            .frame(height: height)
            .clipShape(.rect(cornerRadius: cornerRadius))
            photoRemovalMenu
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
                    .cookleGlassControl(
                        in: Circle()
                    )
            }
            .accessibilityLabel(Text("Photo Actions"))
            .padding(actionButtonPadding)
        }
    }
}
