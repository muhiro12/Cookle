//
//  RecipeTextParser.swift
//  Cookle
//
//  Created by Codex on 2025/06/07.
//

import Foundation

struct RecipeText {
    var name: String
    var ingredients: [RecipeFormIngredient]
    var steps: [String]
}

enum RecipeTextParser {
    static func parse(_ text: String) -> RecipeText {
        let lines = text
            .split(whereSeparator: \._isNewline)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let first = lines.first else {
            return .init(name: "", ingredients: [], steps: [])
        }

        var name = first
        var ingredients = [RecipeFormIngredient]()
        var steps = [String]()

        var mode: Mode = .unknown
        for line in lines.dropFirst() {
            let lower = line.lowercased()
            if lower.contains("ingredients") || line.contains("材料") {
                mode = .ingredients
                continue
            }
            if lower.contains("steps") || lower.contains("directions") || line.contains("作り方") {
                mode = .steps
                continue
            }
            switch mode {
            case .ingredients:
                let parts = line.split(separator: " ", maxSplits: 1)
                if parts.count == 2 {
                    ingredients.append((String(parts[0]), String(parts[1])))
                } else if let separatorIndex = line.firstIndex(of: "：") ?? line.firstIndex(of: ":") {
                    let ing = line[..<separatorIndex]
                    let amt = line[line.index(after: separatorIndex)...]
                    ingredients.append((String(ing).trimmingCharacters(in: .whitespaces), String(amt).trimmingCharacters(in: .whitespaces)))
                } else {
                    ingredients.append((line, ""))
                }
            case .steps:
                steps.append(line)
            case .unknown:
                steps.append(line)
            }
        }

        if steps.isEmpty {
            steps = Array(lines.dropFirst())
        }

        return .init(name: name, ingredients: ingredients, steps: steps)
    }

    private enum Mode {
        case unknown
        case ingredients
        case steps
    }
}
