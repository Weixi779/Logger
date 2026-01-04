import Foundation

/// A structured log record for forwarding to external sinks.
public struct LogRecord: Sendable {
    public let timestamp: Date
    public let level: LogLevel
    public let category: String
    public let subsystem: String
    public let message: String
    public let file: String
    public let function: String
    public let line: Int
    public let metadata: [String: String]
    
    public init(
        timestamp: Date,
        level: LogLevel,
        category: String,
        subsystem: String,
        message: String,
        file: String,
        function: String,
        line: Int,
        metadata: [String: String]
    ) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.subsystem = subsystem
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.metadata = metadata
    }
}
