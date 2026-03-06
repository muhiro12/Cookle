import Foundation
import UIKit
import UserNotifications

final class NotificationAttachmentStore {
    private let fileManager: FileManager
    private let directoryURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directoryURL = Self.makeDirectoryURL(fileManager: fileManager)
    }

    func attachment(
        for recipe: Recipe,
        stableIdentifier: String
    ) -> UNNotificationAttachment? {
        do {
            try ensureDirectoryExists()
            let fileURL = attachmentFileURL(for: stableIdentifier)
            if let cachedAttachment = existingAttachmentIfUpToDate(
                fileURL: fileURL,
                recipeModifiedTimestamp: recipe.modifiedTimestamp,
                stableIdentifier: stableIdentifier
            ) {
                return cachedAttachment
            }
            guard let photo = primaryPhoto(for: recipe),
                  let data = compressedJPEGData(from: photo.data) else {
                try removeItemIfExists(at: fileURL)
                return nil
            }
            try data.write(to: fileURL, options: .atomic)
            return try .init(
                identifier: stableIdentifier,
                url: fileURL
            )
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }

    func pruneAttachments(keepingStableIdentifiers stableIdentifiers: Set<String>) {
        do {
            try ensureDirectoryExists()
            let directoryContents = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            )
            let expectedFileNames = Set(stableIdentifiers.map(attachmentFileName))
            for fileURL in directoryContents {
                guard expectedFileNames.contains(fileURL.lastPathComponent) == false else {
                    continue
                }
                try? fileManager.removeItem(at: fileURL)
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func removeAllAttachments() {
        do {
            guard fileManager.fileExists(atPath: directoryURL.path) else {
                return
            }
            let directoryContents = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            )
            for fileURL in directoryContents {
                try? fileManager.removeItem(at: fileURL)
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

private extension NotificationAttachmentStore {
    static func makeDirectoryURL(fileManager: FileManager) -> URL {
        let baseDirectoryURL: URL
        if let appGroupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: CookleSharedPreferences.appGroupIdentifier
        ) {
            baseDirectoryURL = appGroupURL
        } else {
            baseDirectoryURL = fileManager.urls(
                for: .cachesDirectory,
                in: .userDomainMask
            ).first ?? .temporaryDirectory
        }
        return baseDirectoryURL.appendingPathComponent(
            NotificationConstants.attachmentDirectoryName,
            isDirectory: true
        )
    }

    func ensureDirectoryExists() throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    func primaryPhoto(for recipe: Recipe) -> Photo? {
        if let photo = recipe.photoObjects?.min()?.photo {
            return photo
        }
        return recipe.photos?.first
    }

    func compressedJPEGData(from data: Data) -> Data? {
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 1) else {
            return nil
        }
        return jpegData.compressed()
    }

    func attachmentFileURL(for stableIdentifier: String) -> URL {
        directoryURL.appendingPathComponent(attachmentFileName(stableIdentifier))
    }

    func attachmentFileName(_ stableIdentifier: String) -> String {
        let sanitizedIdentifier = sanitizedFileNameComponent(
            from: stableIdentifier
        )
        return NotificationConstants.attachmentFileNamePrefix
            + sanitizedIdentifier
            + NotificationConstants.attachmentFileNameSuffix
    }

    func sanitizedFileNameComponent(from value: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(
            .init(charactersIn: "-_")
        )
        let sanitized = String(value.unicodeScalars.map { scalar in
            if allowedCharacters.contains(scalar) {
                return Character(scalar)
            }
            return "_"
        })
        return sanitized.isEmpty ? "recipe" : sanitized
    }

    func existingAttachmentIfUpToDate(
        fileURL: URL,
        recipeModifiedTimestamp: Date,
        stableIdentifier: String
    ) -> UNNotificationAttachment? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let resourceValues = try? fileURL.resourceValues(
            forKeys: [.contentModificationDateKey]
        )
        if let contentModificationDate = resourceValues?.contentModificationDate,
           contentModificationDate >= recipeModifiedTimestamp {
            return try? .init(
                identifier: stableIdentifier,
                url: fileURL
            )
        }
        return nil
    }

    func removeItemIfExists(at fileURL: URL) throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        try fileManager.removeItem(at: fileURL)
    }
}
