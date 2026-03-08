import MHPlatform

enum CookleMutationEffectAdapter {
    typealias NotificationSynchronizer = @MainActor @Sendable () async -> Void
    typealias WidgetReloader = @MainActor @Sendable () -> Void

    nonisolated static func make(
        reloadRecipeWidgets: @escaping WidgetReloader = {
            CookleWidgetReloader.reloadRecipeWidgets()
        },
        reloadDiaryWidgets: @escaping WidgetReloader = {
            CookleWidgetReloader.reloadTodayDiaryWidget()
        },
        synchronizeNotifications: @escaping NotificationSynchronizer = {
            // no-op
        },
        reviewFlow: MHReviewFlow? = nil
    ) -> MHMutationAdapter<MutationEffect> {
        .init { effects in
            mutationSteps(
                for: effects,
                reloadRecipeWidgets: reloadRecipeWidgets,
                reloadDiaryWidgets: reloadDiaryWidgets,
                synchronizeNotifications: synchronizeNotifications,
                reviewFlow: reviewFlow
            )
        }
    }
}

private extension CookleMutationEffectAdapter {
    nonisolated static func mutationSteps(
        for effects: MutationEffect,
        reloadRecipeWidgets: @escaping WidgetReloader,
        reloadDiaryWidgets: @escaping WidgetReloader,
        synchronizeNotifications: @escaping NotificationSynchronizer,
        reviewFlow: MHReviewFlow?
    ) -> [MHMutationStep] {
        var steps = [MHMutationStep]()

        if effects.contains(.recipeDataChanged) {
            steps.append(
                .mainActor(
                    name: "reloadRecipeWidgets",
                    action: reloadRecipeWidgets
                )
            )
        }

        if effects.contains(.diaryDataChanged) {
            steps.append(
                .mainActor(
                    name: "reloadDiaryWidgets",
                    action: reloadDiaryWidgets
                )
            )
        }

        if effects.contains(.notificationPlanChanged) {
            steps.append(
                .mainActor(name: "synchronizeNotifications") {
                    await synchronizeNotifications()
                }
            )
        }

        if effects.contains(.reviewPromptEligible),
           let reviewFlow {
            steps.append(
                reviewFlow.step(
                    name: "requestReviewIfNeeded"
                )
            )
        }

        return steps
    }
}
