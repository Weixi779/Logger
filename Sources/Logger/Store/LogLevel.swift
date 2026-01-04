import OSLog
import Foundation

/// Log levels used for filtering and categorizing log entries.
///
/// LogLevel represents the different severity levels of log messages.
/// The enum conforms to CaseIterable, Codable, and Identifiable for easy use
/// in SwiftUI and other contexts.
public enum LogLevel: CaseIterable, Codable, Identifiable, Sendable {
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
