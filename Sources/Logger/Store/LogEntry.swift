import OSLog
import Foundation

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
