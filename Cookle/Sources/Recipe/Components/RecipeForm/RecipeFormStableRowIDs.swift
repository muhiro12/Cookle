import Foundation

enum RecipeFormStableRowIDs {
    struct IndexedRow: Identifiable {
        let id: UUID
        let index: Int
    }

    static func make(count: Int) -> [UUID] {
        (0..<count).map { _ in
            UUID()
        }
    }

    static func indexedRows(
        rowIDs: [UUID],
        count: Int
    ) -> [IndexedRow] {
        zip(rowIDs, 0..<count).map { values in
            .init(
                id: values.0,
                index: values.1
            )
        }
    }

    static func synchronize(
        _ rowIDs: inout [UUID],
        count: Int
    ) {
        if rowIDs.count < count {
            rowIDs.append(
                contentsOf: make(
                    count: count - rowIDs.count
                )
            )
        } else if rowIDs.count > count {
            rowIDs.removeLast(
                rowIDs.count - count
            )
        }
    }
}
