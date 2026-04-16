import CoreGraphics
import MHDesign

enum RecipePreviewLayout {
    static let imageHeight: CGFloat = 240
    static let imageCornerRadius: CGFloat = 8
}

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

enum RecipeStepLayout {
    static let stepNumberOffset = 1
    static let indexWidth: CGFloat = 24
}
