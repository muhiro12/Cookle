/// Outcome returned from workflow mutators.
public struct MutationOutcome<Value> {
    /// Primary value returned by the mutation.
    public let value: Value
    /// Domain signals that adapters can map to side effects.
    public let effects: MutationEffect

    /// Creates a mutation outcome with the produced value and effects.
    public init(
        value: Value,
        effects: MutationEffect = []
    ) {
        self.value = value
        self.effects = effects
    }
}
