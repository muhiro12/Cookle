import Foundation

do {
    let expectedArgumentCount = 2
    guard CommandLine.arguments.count == expectedArgumentCount else {
        throw CocoaError(.fileReadInvalidFileName)
    }
    let projectURL = URL(fileURLWithPath: CommandLine.arguments[1])
    let data = try Data(contentsOf: projectURL)
    // Xcode writes trailing commas; a strict JSON parser cannot read its output.
    let project = try JSONSerialization.jsonObject(with: data, options: [.json5Allowed])
    let output = try JSONSerialization.data(withJSONObject: project, options: [.sortedKeys])
    FileHandle.standardOutput.write(output)
} catch {
    FileHandle.standardError.write(Data("Cannot read Xcode JSON project: \(error.localizedDescription)\n".utf8))
    exit(EXIT_FAILURE)
}
