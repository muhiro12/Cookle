import Foundation

enum DiaryMutationIntentError: LocalizedError {
    case diaryNotFound

    var errorDescription: String? {
        switch self {
        case .diaryNotFound:
            return "Diary not found."
        }
    }
}
