import SwiftUI

struct ShortTitleLabelStyle: LabelStyle {
    func makeBody(configuration: LabelStyleConfiguration) -> some View {
        configuration.title
    }
}
