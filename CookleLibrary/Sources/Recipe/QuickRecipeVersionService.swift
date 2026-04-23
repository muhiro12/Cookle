import Foundation
import FoundationModels

/// Generates temporary quick versions of existing recipes without changing stored recipe data.
@available(iOS 26.0, *)
public enum QuickRecipeVersionService {
    private enum Constants {
        static let maxGeneratedSteps = 6
        static let maxFallbackSteps = 3
        static let fallbackLeadingStepCount = 2
        static let timeReductionDivisor = 3
        static let minimumEstimatedTime = 1
    }

    static var instructions: String {
        """
        You create a temporary quick version of an existing recipe.
        Do not rewrite or mutate the original recipe.
        Return fewer, shorter steps than the original when possible.
        Keep the user's language when practical.
        Do not invent ingredients, exact measurements, or unsupported cooking techniques.
        Do not make food safety guarantees.
        Use 0 for estimated cooking time when it cannot be inferred.
        """
    }

    /// Creates a temporary quick version for display only.
    public static func makeVersion(
        request: QuickRecipeVersionRequest
    ) async throws -> QuickRecipeVersion {
        let normalizedRequest = normalizedRequest(
            request
        )
        guard normalizedRequest.steps.isNotEmpty else {
            throw QuickRecipeVersionError.emptySteps
        }

        let fallbackVersion = fallbackVersion(
            request: normalizedRequest
        )
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable:
            return fallbackVersion
        }

        let session = LanguageModelSession(
            instructions: instructions
        )

        do {
            let generatedVersion = try await session.respond(
                to: prompt(
                    request: normalizedRequest
                ),
                generating: QuickRecipeVersion.self
            ).content
            if let sanitizedVersion = sanitizedVersion(
                generatedVersion,
                request: normalizedRequest
            ) {
                return sanitizedVersion
            }
        } catch {
            // Fall back to deterministic condensation below.
        }

        return fallbackVersion
    }
}

@available(iOS 26.0, *)
extension QuickRecipeVersionService {
    static func prompt(
        request: QuickRecipeVersionRequest
    ) -> String {
        """
        Create a quick display version of this existing recipe.
        Return only the structured fields defined by the schema.

        Recipe name:
        \(request.name)

        Original cooking time:
        \(request.cookingTime) minutes

        Ingredients:
        \(request.ingredients.map { "- \($0)" }.joined(separator: "\n"))

        Original steps:
        \(request.steps.map { "- \($0)" }.joined(separator: "\n"))
        """
    }

    static func normalizedRequest(
        _ request: QuickRecipeVersionRequest
    ) -> QuickRecipeVersionRequest {
        .init(
            name: normalizedText(request.name) ?? .empty,
            cookingTime: max(request.cookingTime, .zero),
            ingredients: request.ingredients.compactMap(normalizedText),
            steps: request.steps.compactMap(normalizedText)
        )
    }

    static func sanitizedVersion(
        _ version: QuickRecipeVersion,
        request: QuickRecipeVersionRequest
    ) -> QuickRecipeVersion? {
        let steps = version.steps
            .compactMap(normalizedText)
            .prefix(Constants.maxGeneratedSteps)
        guard steps.isNotEmpty else {
            return nil
        }

        return .init(
            summary: normalizedText(version.summary) ?? fallbackSummary(
                request: request
            ),
            estimatedCookingTime: sanitizedEstimatedCookingTime(
                version.estimatedCookingTime,
                originalCookingTime: request.cookingTime
            ),
            steps: Array(steps)
        )
    }

    static func fallbackVersion(
        request: QuickRecipeVersionRequest
    ) -> QuickRecipeVersion {
        .init(
            summary: fallbackSummary(
                request: request
            ),
            estimatedCookingTime: fallbackEstimatedCookingTime(
                originalCookingTime: request.cookingTime
            ),
            steps: fallbackSteps(
                from: request.steps
            )
        )
    }
}

@available(iOS 26.0, *)
private extension QuickRecipeVersionService {
    static func fallbackSummary(
        request: QuickRecipeVersionRequest
    ) -> String {
        if request.name.isNotEmpty {
            return "A shorter view of \(request.name) for quick reference."
        }
        return "A shorter view of this recipe for quick reference."
    }

    static func fallbackSteps(
        from steps: [String]
    ) -> [String] {
        guard steps.count > Constants.maxFallbackSteps else {
            return steps
        }

        var quickSteps = Array(
            steps.prefix(Constants.fallbackLeadingStepCount)
        )
        if let finalStep = steps.last,
           quickSteps.contains(finalStep) == false {
            quickSteps.append(finalStep)
        }
        return quickSteps
    }

    static func sanitizedEstimatedCookingTime(
        _ estimatedCookingTime: Int,
        originalCookingTime: Int
    ) -> Int {
        let clampedEstimatedTime = max(
            estimatedCookingTime,
            .zero
        )
        guard originalCookingTime > .zero else {
            return clampedEstimatedTime
        }
        guard clampedEstimatedTime > .zero else {
            return fallbackEstimatedCookingTime(
                originalCookingTime: originalCookingTime
            )
        }
        return min(
            clampedEstimatedTime,
            originalCookingTime
        )
    }

    static func fallbackEstimatedCookingTime(
        originalCookingTime: Int
    ) -> Int {
        guard originalCookingTime > .zero else {
            return .zero
        }
        return max(
            Constants.minimumEstimatedTime,
            originalCookingTime - max(
                Constants.minimumEstimatedTime,
                originalCookingTime / Constants.timeReductionDivisor
            )
        )
    }

    static func normalizedText(
        _ value: String
    ) -> String? {
        let trimmedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard trimmedValue.isNotEmpty else {
            return nil
        }
        return RecipeBlurbService.collapsedWhitespace(
            RecipeBlurbService.strippingListPrefix(
                from: trimmedValue
            )
        )
    }
}
