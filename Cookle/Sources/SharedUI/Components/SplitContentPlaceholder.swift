import SwiftUI

/// Stands in for an unselected `content` column in a three-column split view.
///
/// On iPad the sidebar does not fit alongside `content` and `detail`, so the
/// system drops it and the person sees only the two remaining columns. With no
/// selection those are both empty, which left the Diary, Photos and Tag tabs
/// rendering nothing at all on launch — see
/// https://github.com/muhiro12/Cookle/issues/121
///
/// The list is still reachable through the sidebar toggle in the navigation
/// bar; what was missing was any indication that it exists. This says so
/// instead of leaving the column blank.
struct SplitContentPlaceholder: View {
    private let title: LocalizedStringKey

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "sidebar.left")
        } description: {
            Text("Use the sidebar button to choose from the list.")
        }
    }

    init(_ title: LocalizedStringKey) {
        self.title = title
    }
}

#Preview {
    SplitContentPlaceholder("Nothing Selected")
}
