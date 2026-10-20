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

    @Test(arguments: [false, true])
    func local_only_never_calls_cloud_even_when_local_fails(localFails: Bool) async {
        var cloudCalls = 0
        var localCalls = 0
        var statuses = [RecipeGenerationStatus]()
        do {
            _ = try await RecipeGenerationOperations.generate(
                onDeviceOnly: true,
                cloudUnavailableReason: nil,
                generateWithCloud: {
                    cloudCalls += 1
                    return recipe
                },
                generateOnDevice: {
                    localCalls += 1
                    if localFails {
                        throw Failure.timeout
                    }
                    return recipe
                },
                onStatus: { statuses.append($0) }
            )
            #expect(!localFails)
        } catch {
            #expect(localFails)
        }
        #expect(cloudCalls == 0)
        #expect(localCalls == 1)
        #expect(statuses == [.onDevice()])
    }

    @Test
    func automatic_uses_cloud_without_a_second_request_on_success() async throws {
        var localCalls = 0
        var statuses = [RecipeGenerationStatus]()
        let result = try await RecipeGenerationOperations.generate(
            onDeviceOnly: false,
            cloudUnavailableReason: nil,
            generateWithCloud: { recipe },
            generateOnDevice: {
                localCalls += 1
                return recipe
            },
            onStatus: { statuses.append($0) }
        )
        #expect(result == recipe)
        #expect(localCalls == 0)
        #expect(statuses == [.privateCloudCompute])
    }

    @Test(arguments: RecipeGenerationStatus.FallbackReason.allCases)
    func recoverable_cloud_failure_reports_the_reason_and_attempts_local_once(
        reason: RecipeGenerationStatus.FallbackReason
    ) async throws {
        var localCalls = 0
        var statuses = [RecipeGenerationStatus]()
        _ = try await RecipeGenerationOperations.generate(
            onDeviceOnly: false,
            cloudUnavailableReason: nil,
            generateWithCloud: { throw reason },
            generateOnDevice: {
                localCalls += 1
                return recipe
            },
            onStatus: { statuses.append($0) }
        )
        #expect(localCalls == 1)
        #expect(statuses == [.privateCloudCompute, .onDevice(fallbackReason: reason)])
    }

    @Test(arguments: [RecipeGenerationStatus.FallbackReason.unavailable, .quotaLimitReached])
    func known_cloud_unavailability_skips_cloud_and_keeps_the_reason(
        reason: RecipeGenerationStatus.FallbackReason
    ) async throws {
        var cloudCalls = 0
        var statuses = [RecipeGenerationStatus]()
        _ = try await RecipeGenerationOperations.generate(
            onDeviceOnly: false,
            cloudUnavailableReason: reason,
            generateWithCloud: {
                cloudCalls += 1
                return recipe
            },
            generateOnDevice: { recipe },
            onStatus: { statuses.append($0) }
        )
        #expect(cloudCalls == 0)
        #expect(statuses == [.onDevice(fallbackReason: reason)])
    }

    @Test(arguments: [Failure.refusal, .timeout])
    func nonrecoverable_model_errors_do_not_switch_models(failure: Failure) async {
        var localCalls = 0
        do {
            _ = try await RecipeGenerationOperations.generate(
                onDeviceOnly: false,
                cloudUnavailableReason: nil,
                generateWithCloud: { throw failure },
                generateOnDevice: {
                    localCalls += 1
                    return recipe
                },
                onStatus: { _ in
                    // These cases assert model calls and cancellation rather than status presentation.
                }
            )
            Issue.record("The model failure must be surfaced.")
        } catch {
            #expect(error is Failure)
        }
        #expect(localCalls == 0)
    }

    @Test
    func a_failed_local_fallback_does_not_retry_cloud() async {
        var cloudCalls = 0
        var localCalls = 0
        do {
            _ = try await RecipeGenerationOperations.generate(
                onDeviceOnly: false,
                cloudUnavailableReason: nil,
                generateWithCloud: {
                    cloudCalls += 1
                    throw RecipeGenerationStatus.FallbackReason.networkFailure
                },
                generateOnDevice: {
                    localCalls += 1
                    throw Failure.timeout
                },
                onStatus: { _ in
                    // These cases assert model calls and cancellation rather than status presentation.
                }
            )
            Issue.record("The local failure must be surfaced.")
        } catch {
            #expect(error is Failure)
        }
        #expect(cloudCalls == 1)
        #expect(localCalls == 1)
    }

    @Test(arguments: [false, true])
    func cancellation_during_cloud_never_starts_local(useServiceError: Bool) async {
        var localCalls = 0
        let operation = Task {
            try await RecipeGenerationOperations.generate(
                onDeviceOnly: false,
                cloudUnavailableReason: nil,
                generateWithCloud: {
                    if useServiceError {
                        withUnsafeCurrentTask { $0?.cancel() }
                        throw RecipeGenerationStatus.FallbackReason.networkFailure
                    }
                    throw CancellationError()
                },
                generateOnDevice: {
                    localCalls += 1
                    return recipe
                },
                onStatus: { _ in
                    // These cases assert model calls and cancellation rather than status presentation.
                }
            )
        }
        do {
            _ = try await operation.value
            Issue.record("Cancellation must be propagated.")
        } catch {
            #expect(error is CancellationError)
        }
        #expect(localCalls == 0)
    }

    @Test(arguments: [false, true])
    func a_late_response_after_cancellation_is_not_returned(onDeviceOnly: Bool) async {
        let operation = Task {
            try await RecipeGenerationOperations.generate(
                onDeviceOnly: onDeviceOnly,
                cloudUnavailableReason: nil,
                generateWithCloud: {
                    withUnsafeCurrentTask { $0?.cancel() }
                    return recipe
                },
                generateOnDevice: {
                    withUnsafeCurrentTask { $0?.cancel() }
                    return recipe
                },
                onStatus: { _ in
                    // These cases assert model calls and cancellation rather than status presentation.
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

    @Test(arguments: [false, true])
    func cancelling_at_the_processing_update_prevents_any_model_request(onDeviceOnly: Bool) async {
        var modelCalls = 0
        let operation = Task {
            try await RecipeGenerationOperations.generate(
                onDeviceOnly: onDeviceOnly,
                cloudUnavailableReason: nil,
                generateWithCloud: {
                    modelCalls += 1
                    return recipe
                },
                generateOnDevice: {
                    modelCalls += 1
                    return recipe
                },
                onStatus: { _ in
                    withUnsafeCurrentTask { $0?.cancel() }
                }
            )
        }
        do {
            _ = try await operation.value
            Issue.record("Cancellation before the model call must be propagated.")
        } catch {
            #expect(error is CancellationError)
        }
        #expect(modelCalls == 0)
    }
}
