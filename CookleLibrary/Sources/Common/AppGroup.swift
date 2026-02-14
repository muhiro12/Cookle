import Foundation

enum AppGroup {
    static let id = "group.com.muhiro12.Cookle"
    static let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)!
}
