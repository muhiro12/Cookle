import CoreGraphics
import MHUI

enum RecipeTextEditorLayout {
    static let placeholderHorizontalPadding: CGFloat = 6

    static func placeholderVerticalPadding(
        metrics: MHDesignMetrics
    ) -> CGFloat {
        metrics.spacing.inline
    }

    static func cornerRadius(
        metrics: MHDesignMetrics
    ) -> CGFloat {
        metrics.cornerRadius.control
    }
}
