import CookleLibrary
import Foundation
import Testing

@MainActor
struct RecipeGenerationRoutingTests {
    enum Failure: Error {
        case refusal
        case timeout
    }

    private var recipe: RecipeInferenceResult {
        .init(
            name: "Tofu",
            servingSize: 2,
            cookingTime: 10,
            ingredients: [.init(ingredient: "Tofu", amount: "300 g")],
            steps: ["Cook the tofu."],
            categories: [],
            note: ""
        )
    }

    @Test
    func a_successful_cloud_request_returns_one_draft() async throws {
        var cloudCalls = 0
        var statuses = [RecipeGenerationStatus]()
        let result = try await RecipeGenerationOperations.generate(
            unavailableReason: nil,
            generateWithCloud: {
                cloudCalls += 1
                return recipe
            },
            onStatus: { statuses.append($0) }
        )
        #expect(result == recipe)
        #expect(cloudCalls == 1)
        #expect(statuses == [.privateCloudCompute])
    }

    @Test(arguments: [RecipeGenerationError.unavailable, .quotaLimitReached])
    func known_unavailability_stops_before_starting_a_request(reason: RecipeGenerationError) async {
        var cloudCalls = 0
        var statuses = [RecipeGenerationStatus]()
        do {
            _ = try await RecipeGenerationOperations.generate(
                unavailableReason: reason,
                generateWithCloud: {
                    cloudCalls += 1
                    return recipe
                },
                onStatus: { statuses.append($0) }
            )
            Issue.record("Unavailable generation must not return a draft.")
        } catch {
            #expect(error as? RecipeGenerationError == reason)
        }
        #expect(cloudCalls == 0)
        #expect(statuses.isEmpty)
    }

    @Test(arguments: RecipeGenerationError.allCases)
    func cloud_failures_are_surfaced_without_a_retry_or_substitute(reason: RecipeGenerationError) async {
        var cloudCalls = 0
        var statuses = [RecipeGenerationStatus]()
        do {
            _ = try await RecipeGenerationOperations.generate(
                unavailableReason: nil,
                generateWithCloud: {
                    cloudCalls += 1
                    throw reason
                },
                onStatus: { statuses.append($0) }
            )
            Issue.record("A failed cloud request must not return a draft.")
        } catch {
            #expect(error as? RecipeGenerationError == reason)
        }
        #expect(cloudCalls == 1)
        #expect(statuses == [.privateCloudCompute])
    }

    @Test(arguments: [Failure.refusal, .timeout])
    func other_model_errors_are_preserved(failure: Failure) async {
        var cloudCalls = 0
        do {
            _ = try await RecipeGenerationOperations.generate(
                unavailableReason: nil,
                generateWithCloud: {
                    cloudCalls += 1
                    throw failure
                },
                onStatus: { _ in
                    // Status presentation is covered by the success and cloud-error cases.
                }
            )
            Issue.record("The model failure must be surfaced.")
        } catch {
            #expect(error as? Failure == failure)
        }
        #expect(cloudCalls == 1)
    }

    @Test(arguments: [false, true])
    func cancellation_during_cloud_takes_precedence_over_a_service_error(useServiceError: Bool) async {
        let operation = Task {
            try await RecipeGenerationOperations.generate(
                unavailableReason: nil,
                generateWithCloud: {
                    if useServiceError {
                        withUnsafeCurrentTask { $0?.cancel() }
                        throw RecipeGenerationError.networkFailure
                    }
                    throw CancellationError()
                },
                onStatus: { _ in
                    // This case verifies cancellation rather than status presentation.
                }
            )
        }
        do {
            _ = try await operation.value
            Issue.record("Cancellation must be propagated.")
        } catch {
            #expect(error is CancellationError)
        }
    }

    @Test
    func a_late_response_after_cancellation_is_not_returned() async {
        let operation = Task {
            try await RecipeGenerationOperations.generate(
                unavailableReason: nil,
                generateWithCloud: {
                    withUnsafeCurrentTask { $0?.cancel() }
                    return recipe
                },
                onStatus: { _ in
                    // This case verifies cancellation rather than status presentation.
                }
            )
        }
        do {
            _ = try await operation.value
            Issue.record("A cancelled response must not be returned to the form.")
        } catch {
            #expect(error is CancellationError)
        }
    }

    @Test
    func cancelling_at_the_processing_update_prevents_the_cloud_request() async {
        var cloudCalls = 0
        let operation = Task {
            try await RecipeGenerationOperations.generate(
                unavailableReason: nil,
                generateWithCloud: {
                    cloudCalls += 1
                    return recipe
                },
                onStatus: { _ in
                    withUnsafeCurrentTask { $0?.cancel() }
                }
            )
        }
        do {
            _ = try await operation.value
            Issue.record("Cancellation before the cloud call must be propagated.")
        } catch {
            #expect(error is CancellationError)
        }
        #expect(cloudCalls == 0)
    }
}
