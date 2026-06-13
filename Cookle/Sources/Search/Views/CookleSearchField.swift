import SwiftUI

struct CookleSearchField: View {
    private enum Layout {
        static let spacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 10
        static let cornerRadius: CGFloat = 12
    }

    @Binding private var text: String

    private let isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Search", text: $text, prompt: Text("Search"))
                .focused(isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Clear Search"))
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .cookleGlassControl(
            in: RoundedRectangle(
                cornerRadius: Layout.cornerRadius,
                style: .continuous
            )
        )
    }

    init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding
    ) {
        _text = text
        self.isFocused = isFocused
    }
}

#Preview {
    @Previewable @State var text = "Carbonara"
    @FocusState var isFocused: Bool

    CookleSearchField(
        text: $text,
        isFocused: $isFocused
    )
    .padding()
}
