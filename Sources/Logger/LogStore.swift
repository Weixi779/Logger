import OSLog
import Foundation

public class LogStore {
    private let store: OSLogStore
    private let subsystem: String
    
    public init() throws {
        self.store = try OSLogStore(scope: .currentProcessIdentifier)
        self.subsystem = Bundle.main.bundleIdentifier ?? "app"
    }
    
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
    
    public func exportLogsAsJSON(
        since: Date,
        until: Date = Date(),
        levels: [LogLevel] = [.all]
    ) throws -> Data {
        let logs = try getLogs(since: since, until: until, levels: levels)
        return try JSONEncoder().encode(logs)
    }
    
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

public struct LogEntry: Codable {
    public let timestamp: Date
    public let level: LogLevel
    public let category: String
    public let message: String
    public let subsystem: String
    
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

public enum LogLevel: CaseIterable, Codable, Identifiable {
    case debug, info, notice, error, fault, all
    
    public var id: Self { self }
    
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