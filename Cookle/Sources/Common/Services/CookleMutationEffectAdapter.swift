import MHMutationFlow
import MHReviewPolicy

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
        let baseAdapter: MHMutationAdapter<MutationEffect> = .build { effects in
            if effects.contains(.recipeDataChanged) {
                MHMutationStep.mainActor(
                    name: "reloadRecipeWidgets",
                    action: reloadRecipeWidgets
                )
            }

            if effects.contains(.diaryDataChanged) {
                MHMutationStep.mainActor(
                    name: "reloadDiaryWidgets",
                    action: reloadDiaryWidgets
                )
            }

            if effects.contains(.notificationPlanChanged) {
                MHMutationStep.mainActor(
                    name: "synchronizeNotifications"
                ) {
                    await synchronizeNotifications()
                }
            }
        }

        guard let reviewFlow else {
            return baseAdapter
        }

        let reviewAdapter: MHMutationAdapter<MutationEffect> = .build { effects in
            if effects.contains(.reviewPromptEligible) {
                reviewFlow.step(
                    name: "requestReviewIfNeeded"
                )
            }
        }

        return baseAdapter.appending(reviewAdapter)
    }
}
