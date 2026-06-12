import Foundation

extension StringProtocol {
    func normalizedContains<T>(
        _ other: T
    ) -> Bool where T: StringProtocol {
        let normalizedSelf = self
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false) ?? ""

        let normalizedOther = other
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false) ?? ""

        return normalizedSelf.localizedStandardContains(normalizedOther)
    }
}
