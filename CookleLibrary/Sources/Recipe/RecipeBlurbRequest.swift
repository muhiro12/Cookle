/// Input used to derive a short deterministic recipe blurb.
public struct RecipeBlurbRequest: Sendable {
    public let steps: [String]
    public let ingredients: [String]
    public let note: String

    public init(
        steps: [String],
        ingredients: [String],
        note: String
    ) {
        self.steps = steps
        self.ingredients = ingredients
        self.note = note
    }
}
