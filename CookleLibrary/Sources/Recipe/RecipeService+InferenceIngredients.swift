import Foundation

extension RecipeService {
    private static let ingredientTableColumnCount = 2

    static func fallbackIngredients(from rows: [String]) -> [RecipeInferenceIngredient] {
        var result = [RecipeInferenceIngredient]()
        var readsTable = false
        for (index, row) in rows.enumerated() {
            let cells = ingredientTableCells(row)
            if cells.count == ingredientTableColumnCount,
               ingredientSectionHeadings.contains(normalizedHeading(cells[0])),
               ["amount", "quantity", "分量", "quantité", "cantidad", "用量"].contains(normalizedHeading(cells[1])),
               rows.indices.contains(index + 1),
               isIngredientTableSeparator(rows[index + 1]) {
                readsTable = true
                continue
            }
            if readsTable, isIngredientTableSeparator(row) {
                continue
            }
            if readsTable, cells.count == ingredientTableColumnCount, !cells[0].isEmpty {
                result.append(.init(ingredient: cells[0], amount: cells[1]))
            } else {
                readsTable = false
                result.append(fallbackIngredient(from: row))
            }
        }
        return result
    }

    private static func fallbackIngredient(from row: String) -> RecipeInferenceIngredient {
        if let separator = row.firstIndex(where: { $0 == ":" || $0 == "：" }) {
            let name = row[..<separator].trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                return .init(
                    ingredient: name,
                    amount: row[row.index(after: separator)...].trimmingCharacters(in: .whitespaces)
                )
            }
        }
        // Split only explicit trailing amounts; keep ambiguous units and unitless names literal.
        let pattern = #/
                (?x)
                ^(.*?) \s+
                (
                [0-9０-９]+ (?: [./〜～–-] [0-9０-９]+ )? \s*
                (?: kg | mg | g | ml | mL | L | l | cups? | tbsp | tsp | slices? | 個 | 本 | 枚 )
                | a \s+ pinch | 少々 | 適量
                )$
                /#
        // An earlier number may belong to a mixed fraction or range, not the ingredient name.
        if let match = row.wholeMatch(of: pattern), !match.1.isEmpty,
           !match.1.contains(where: \.isNumber) {
            return .init(ingredient: String(match.1), amount: String(match.2))
        }
        return .init(ingredient: row, amount: "")
    }

    private static func ingredientTableCells(_ row: String) -> [String] {
        guard row.hasPrefix("|"), row.hasSuffix("|") else {
            return []
        }
        return row.dropFirst().dropLast().split(separator: "|", omittingEmptySubsequences: false).map { cell in
            cell.trimmingCharacters(in: .whitespaces)
        }
    }

    private static func isIngredientTableSeparator(_ row: String) -> Bool {
        let cells = ingredientTableCells(row)
        return cells.count == ingredientTableColumnCount && cells.allSatisfy { cell in
            cell.range(of: #"^:?-{3,}:?$"#, options: .regularExpression) != nil
        }
    }
}
