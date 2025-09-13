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

/// Represents a single log entry retrieved from the system log store.
/// 
/// LogEntry provides access to all the key information from a log entry including
/// timestamp, level, category, message, and subsystem. It also retains a reference
/// to the original OSLogEntryLog for advanced use cases.
/// 
/// The struct is Codable, so it can be easily serialized to JSON or other formats,
/// though the rawEntry field is excluded from encoding.
public struct LogEntry: Codable {
    /// The timestamp when the log entry was created
    public let timestamp: Date
    
    /// The log level (debug, info, notice, error, fault)
    public let level: LogLevel
    
    /// The category this log entry belongs to
    public let category: String
    
    /// The actual log message content
    public let message: String
    
    /// The subsystem (typically your app's bundle identifier)
    public let subsystem: String
    
    /// The original OSLogEntryLog object for advanced use cases
    /// - Note: This field is not included in JSON encoding
    public let rawEntry: OSLogEntryLog
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, level, category, message, subsystem
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(level, forKey: .level)
        try container.encode(category, forKey: .category)
        try container.encode(message, forKey: .message)
        try container.encode(subsystem, forKey: .subsystem)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        level = try container.decode(LogLevel.self, forKey: .level)
        category = try container.decode(String.self, forKey: .category)
        message = try container.decode(String.self, forKey: .message)
        subsystem = try container.decode(String.self, forKey: .subsystem)
        rawEntry = OSLogEntryLog()
    }
    
    init(timestamp: Date, level: LogLevel, category: String, message: String, subsystem: String, rawEntry: OSLogEntryLog) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.subsystem = subsystem
        self.rawEntry = rawEntry
    }
}

/// Log levels used for filtering and categorizing log entries.
/// 
/// LogLevel represents the different severity levels of log messages.
/// The enum conforms to CaseIterable, Codable, and Identifiable for easy use
/// in SwiftUI and other contexts.
public enum LogLevel: CaseIterable, Codable, Identifiable {
    /// Debug messages (typically not persisted in release builds)
    case debug
    /// Informational messages
    case info
    /// Notice messages for significant events
    case notice
    /// Error messages for error conditions
    case error
    /// Fault messages for critical system errors
    case fault
    /// Special case for "all levels" filtering
    case all
    
    public var id: Self { self }
    
    /// Human-readable display name for the log level.
    /// - Returns: Uppercase string representation of the log level
    public var displayName: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .notice: return "NOTICE"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        case .all: return "ALL"
        }
    }
    
    /// Converts an OSLogEntryLog.Level to our LogLevel enum.
    /// - Parameter osLevel: The system log level to convert
    /// - Returns: The corresponding LogLevel case
    static func from(_ osLevel: OSLogEntryLog.Level) -> LogLevel {
        switch osLevel {
        case .debug: return .debug
        case .info: return .info
        case .notice: return .notice
        case .error: return .error
        case .fault: return .fault
        default: return .info
        }
    }
}