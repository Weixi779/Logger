import OSLog
import Foundation

/// A log store that provides access to persisted logs using Apple's OSLogStore.
///
/// LogStore allows you to retrieve, filter, and export logs that were written by your application.
/// It automatically filters logs by the current app's subsystem and provides convenient export methods.
///
/// - Important: Requires iOS 15.0+, macOS 12.0+, tvOS 15.0+, or watchOS 8.0+
public class LogStore {
    private let store: OSLogStore
    private let subsystem: String
    
    /// Creates a new LogStore instance for the current process.
    /// - Throws: OSLogStore.Error if the log store cannot be accessed
    public init() throws {
        self.store = try OSLogStore(scope: .currentProcessIdentifier)
        self.subsystem = Bundle.main.bundleIdentifier ?? "app"
    }
    
    /// Retrieves log entries from the system log store with optional filtering.
    ///
    /// This method queries the system log store for entries from your app and returns them
    /// as an array of LogEntry objects. You can filter by time range and log levels.
    ///
    /// - Parameters:
    ///   - since: The earliest date to include in the results
    ///   - until: The latest date to include in the results (defaults to current time)
    ///   - levels: An array of log levels to include (defaults to all levels)
    /// - Returns: An array of LogEntry objects matching the specified criteria
    /// - Throws: OSLogStore.Error if the query fails
    public func getLogs(
        since: Date,
        until: Date = Date(),
        levels: [LogLevel] = [.all]
    ) throws -> [LogEntry] {
        let predicate = createPredicate()
        let startPosition = store.position(date: since)
        
        return try store.getEntries(at: startPosition, matching: predicate)
            .compactMap { entry -> LogEntry? in
                guard let logEntry = entry as? OSLogEntryLog,
                      logEntry.date <= until else { return nil }
                
                let level = LogLevel.from(logEntry.level)
                
                if levels.contains(.all) || levels.contains(level) {
                    return LogEntry(
                        timestamp: logEntry.date,
                        level: level,
                        category: logEntry.category,
                        message: logEntry.composedMessage,
                        subsystem: logEntry.subsystem,
                        rawEntry: logEntry
                    )
                }
                return nil
            }
    }
    
    /// Exports filtered log entries as JSON data.
    ///
    /// This method is convenient for programmatic processing of logs or when you need
    /// to send log data to external services. The JSON includes all log entry fields
    /// except the raw OSLogEntryLog object.
    ///
    /// - Parameters:
    ///   - since: The earliest date to include in the export
    ///   - until: The latest date to include in the export (defaults to current time)
    ///   - levels: An array of log levels to include (defaults to all levels)
    /// - Returns: JSON-encoded log data
    /// - Throws: OSLogStore.Error if the query fails, or EncodingError if JSON encoding fails
    public func exportLogsAsJSON(
        since: Date,
        until: Date = Date(),
        levels: [LogLevel] = [.all]
    ) throws -> Data {
        let logs = try getLogs(since: since, until: until, levels: levels)
        return try JSONEncoder().encode(logs)
    }
    
    /// Exports filtered log entries as human-readable text.
    ///
    /// This method formats logs as readable text, perfect for sharing with users,
    /// support teams, or for manual inspection. Each log entry is formatted on a single line
    /// with timestamp, level, category, and message.
    ///
    /// - Parameters:
    ///   - since: The earliest date to include in the export
    ///   - until: The latest date to include in the export (defaults to current time)
    ///   - levels: An array of log levels to include (defaults to all levels)
    /// - Returns: Formatted text string with one log entry per line
    /// - Throws: OSLogStore.Error if the query fails
    public func exportLogsAsText(
        since: Date,
        until: Date = Date(),
        levels: [LogLevel] = [.all]
    ) throws -> String {
        let logs = try getLogs(since: since, until: until, levels: levels)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        return logs.map { entry in
            "[\(formatter.string(from: entry.timestamp))] [\(entry.level.displayName)] [\(entry.category)] \(entry.message)"
        }.joined(separator: "\n")
    }
    
    private func createPredicate() -> NSPredicate {
        return NSPredicate(format: "subsystem == %@", subsystem)
    }
}
