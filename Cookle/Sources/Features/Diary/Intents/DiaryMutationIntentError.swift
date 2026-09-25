import Foundation

enum DiaryMutationIntentError: LocalizedError, CustomLocalizedStringResourceConvertible {
    case diaryNotFound

    var errorDescription: String? {
        String(localized: localizedStringResource)
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .diaryNotFound:
            return "Diary not found."
        }
    }
}
