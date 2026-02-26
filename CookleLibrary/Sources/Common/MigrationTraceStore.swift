import Foundation

public enum MigrationTraceStore {
    private static let logsKey = "cookle_migration_trace_logs_v1"
    private static let maximumLogCount = 500
    private static let queue = DispatchQueue(label: "CookleLibrary.MigrationTraceStore")

    public static func append(_ message: String) {
        queue.sync {
            var logs = storedLogs()
            let timestamp = nowTimestampString()
            logs.append("[\(timestamp)] \(message)")
            if logs.count > maximumLogCount {
                logs.removeFirst(logs.count - maximumLogCount)
            }
            UserDefaults.standard.set(logs, forKey: logsKey)
        }
    }

    public static func load() -> [String] {
        queue.sync {
            storedLogs()
        }
    }

    public static func clear() {
        queue.sync {
            UserDefaults.standard.removeObject(forKey: logsKey)
        }
    }
}

private extension MigrationTraceStore {
    static func nowTimestampString() -> String {
        let formatter: ISO8601DateFormatter = .init()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: .now)
    }

    static func storedLogs() -> [String] {
        UserDefaults.standard.stringArray(forKey: logsKey) ?? []
    }
}
