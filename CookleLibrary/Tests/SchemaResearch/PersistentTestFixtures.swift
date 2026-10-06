import Foundation

/// Core Data may retain SQLite handles after a ModelContainer leaves scope.
/// Keep each disposable fixture until the test process exits; verification
/// removes only emitted roots after the assigned Simulator has shut down.
func persistentTestDirectory(fileManager: FileManager) throws -> URL {
    let directory = fileManager.temporaryDirectory.appendingPathComponent(
        "CookleSchemaResearchTests-" + UUID().uuidString,
        isDirectory: true
    )
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    print("CookleSchemaResearch persistent fixture directory: " + directory.path)
    return directory
}
