import Foundation

extension RecipeService {
    static func fallbackName(from lines: [String]) -> String {
        for line in lines {
            let normalizedLine = sanitizedInferenceLine(
                strippedInferenceMarkup(line)
            )
            guard !normalizedLine.isEmpty else {
                continue
            }
            guard inlineSectionItem(
                from: normalizedLine,
                headings: allSectionHeadings
            ) == nil else {
                continue
            }
            return normalizedLine
        }
        return ""
    }

    static func fallbackSectionItems(
        from lines: [String],
        headings: [String],
        joinsIndentedContinuations: Bool = false
    ) -> [String] {
        var collectedItems = [String]()
        var isCollecting = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else {
                continue
            }

            if let inlineItem = inlineSectionItem(
                from: trimmedLine,
                headings: headings
            ) {
                isCollecting = true
                let normalizedItem = sanitizedInferenceLine(
                    RecipeBlurbService.strippingListPrefix(
                        from: inlineItem
                    )
                )
                if !normalizedItem.isEmpty {
                    collectedItems.append(normalizedItem)
                }
                continue
            }

            if inlineSectionItem(
                from: trimmedLine,
                headings: allSectionHeadings
            ) != nil || cookingTimeStatement(in: trimmedLine) != nil {
                if isCollecting {
                    break
                }
                continue
            }

            guard isCollecting else {
                continue
            }

            let normalizedItem = sanitizedInferenceLine(
                strippedInferenceMarkup(trimmedLine)
            )
            if !normalizedItem.isEmpty {
                let isIndented = line.first?.isWhitespace == true
                let isListItem = RecipeBlurbService.strippingListPrefix(from: trimmedLine) != trimmedLine
                if joinsIndentedContinuations, isIndented, !isListItem, !collectedItems.isEmpty {
                    collectedItems[collectedItems.count - 1] += "\n" + normalizedItem
                } else {
                    collectedItems.append(normalizedItem)
                }
            }
        }

        return collectedItems
    }

    static func inlineSectionItem(
        from line: String,
        headings: [String]
    ) -> String? {
        let normalizedLine = strippedInferenceMarkup(line)
        let separators = [":", "："]

        for separator in separators {
            guard let separatorRange = normalizedLine.range(of: separator) else {
                continue
            }

            let heading = String(normalizedLine[..<separatorRange.lowerBound])
            guard matchesSectionHeading(
                heading,
                headings: headings
            ) else {
                continue
            }

            return String(normalizedLine[separatorRange.upperBound...])
        }

        guard matchesSectionHeading(
            normalizedLine,
            headings: headings
        ) else {
            return nil
        }
        return ""
    }

    static func matchesSectionHeading(
        _ value: String,
        headings: [String]
    ) -> Bool {
        let normalizedValue = normalizedHeading(value)
        return headings.contains(normalizedValue)
    }

    static func normalizedHeading(
        _ value: String
    ) -> String {
        let trimmedValue = RecipeBlurbService.strippingListPrefix(
            from: value
        )
        let trimmedPunctuation = trimmedValue.trimmingCharacters(
            in: CharacterSet.punctuationCharacters.union(
                .whitespacesAndNewlines
            )
        )
        return RecipeBlurbService.collapsedWhitespace(
            trimmedPunctuation
        )
        .replacingOccurrences(of: " ", with: "")
        .lowercased()
    }

    static func strippedInferenceMarkup(_ value: String) -> String {
        var result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        result = result.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
        let boldMarker = "**"
        if !result.hasPrefix(boldMarker) {
            result = RecipeBlurbService.strippingListPrefix(from: result)
        }
        if result.hasPrefix(boldMarker), result.hasSuffix(boldMarker),
           result.count > boldMarker.count + boldMarker.count {
            result = String(result.dropFirst(boldMarker.count).dropLast(boldMarker.count))
        }
        return result
    }
}
