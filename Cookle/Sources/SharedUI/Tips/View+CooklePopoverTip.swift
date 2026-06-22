import SwiftUI
import TipKit

extension View {
    @ViewBuilder
    func cooklePopoverTip(
        _ tip: (any Tip)?,
        arrowEdge: Edge = .top
    ) -> some View {
        if CookleTipController.shouldSuppressPopoverTips {
            self
        } else {
            popoverTip(
                tip,
                arrowEdge: arrowEdge
            )
        }
    }
}
