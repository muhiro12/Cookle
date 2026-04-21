import CryptoKit
import Foundation
import UIKit

nonisolated final class NotificationAttachmentStore {
    private let fileManager: FileManager
    private let directoryURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directoryURL = Self.makeDirectoryURL(fileManager: fileManager)
    }

    func prepareAttachmentFileURL(
        for snapshot: NotificationRecipeSnapshot
    ) -> URL? {
        do {
            try ensureDirectoryExists()
            let fileURL = attachmentFileURL(
                for: snapshot.stableIdentifier
            )
            if let cachedFileURL = existingAttachmentFileURLIfUpToDate(
                fileURL: fileURL,
                recipeModifiedTimestamp: snapshot.modifiedTimestamp
            ) {
                return cachedFileURL
            }
            guard let photoData = snapshot.primaryPhotoData,
                  let data = compressedJPEGData(from: photoData) else {
                try removeItemIfExists(at: fileURL)
                return nil
            }
            try data.write(to: fileURL, options: .atomic)
            return fileURL
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

nonisolated private extension NotificationAttachmentStore {
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
        let hashedIdentifier = hashedFileNameComponent(
            from: stableIdentifier
        )
        return NotificationConstants.attachmentFileNamePrefix
            + hashedIdentifier
            + NotificationConstants.attachmentFileNameSuffix
    }

    func hashedFileNameComponent(from value: String) -> String {
        let digest = SHA256.hash(
            data: Data(value.utf8)
        )
        return digest
            .map { byte in
                String(format: "%02x", byte)
            }
            .joined()
    }

    func existingAttachmentFileURLIfUpToDate(
        fileURL: URL,
        recipeModifiedTimestamp: Date
    ) -> URL? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let resourceValues = try? fileURL.resourceValues(
            forKeys: [.contentModificationDateKey]
        )
        if let contentModificationDate = resourceValues?.contentModificationDate,
           contentModificationDate >= recipeModifiedTimestamp {
            return fileURL
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
