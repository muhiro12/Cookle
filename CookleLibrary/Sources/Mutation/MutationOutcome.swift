/// Result returned from a domain mutation, including follow-up side-effect hints.
public struct MutationOutcome<Value> {
    /// Domain value produced by the mutation.
    public let value: Value
    /// Side-effect hints that app adapters can translate into refreshes or notifications.
    public let effects: MutationEffect

    /// Creates a mutation result with an optional set of follow-up side-effect hints.
    public init(
        value: Value,
        effects: MutationEffect = []
    ) {
        self.value = value
        self.effects = effects
    }
}
