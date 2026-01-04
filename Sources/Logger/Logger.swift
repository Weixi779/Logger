import os
import OSLog
import Foundation

/// A logging utility built on top of Apple's unified logging system (os.Logger) with performance measurement capabilities.
/// 
/// Logger provides structured logging with automatic source context and performance measurement using OSSignposter.
/// It supports multiple log levels and can be used for both development debugging and production monitoring.
public struct Logger: @unchecked Sendable {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app"
    public static let defaultCategory = "Default"
    private let logger: os.Logger
    private let signposter: OSSignposter
    private let category: String

    /// Creates a Logger instance with a custom category string.
    /// - Parameter category: The category name for this logger instance
    public init(category: String = Logger.defaultCategory) {
        let normalizedCategory = Logger.normalizedCategory(category)
        self.logger = .init(subsystem: Self.subsystem, category: normalizedCategory)
        self.signposter = OSSignposter(logger: self.logger)
        self.category = normalizedCategory
    }

    private static func context(_ file: StaticString,
                                _ function: StaticString,
                                _ line: Int) -> String {
        "[\(file):\(line)] \(function)"
    }
    
    private static func normalizedCategory(_ category: String) -> String {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultCategory : trimmed
    }
    
    private func emitRecord(level: LogLevel,
                            msg: String,
                            metadata: [String: String],
                            file: StaticString,
                            function: StaticString,
                            line: Int) {
        let record = LogRecord(
            timestamp: Date(),
            level: level,
            category: category,
            subsystem: Self.subsystem,
            message: msg,
            file: String(describing: file),
            function: String(describing: function),
            line: line,
            metadata: metadata
        )
        LogPipeline.shared.emit(record)
    }
    
    /// Sets global configuration for all Logger instances.
    /// - Note: Intended to be configured once during app startup.
    public static func bootstrap(_ configuration: LoggerConfiguration) {
        LogPipeline.shared.bootstrap(configuration)
    }
    
    /// Returns the current global logger configuration.
    public static var currentConfiguration: LoggerConfiguration {
        LogPipeline.shared.currentConfiguration()
    }

    #if DEBUG
    static func resetForTesting() {
        LogPipeline.shared.resetForTesting()
    }
    #endif

    /// Logs an informational message.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - metadata: Optional key-value pairs attached to the log record
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public func info(_ msg: String,
                     metadata: [String: String] = [:],
                     file: StaticString = #fileID,
                     function: StaticString = #function,
                     line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.info("\(msg, privacy: .private)\n\(suffix)")
        emitRecord(level: .info, msg: msg, metadata: metadata, file: file, function: function, line: line)
    }

    /// Logs a debug message. Debug logs are typically not persisted in release builds.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - metadata: Optional key-value pairs attached to the log record
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public func debug(_ msg: String,
                      metadata: [String: String] = [:],
                      file: StaticString = #fileID,
                      function: StaticString = #function,
                      line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.debug("\(msg, privacy: .private)\n\(suffix)")
        emitRecord(level: .debug, msg: msg, metadata: metadata, file: file, function: function, line: line)
    }

    /// Logs a notice message for significant events that are not errors.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - metadata: Optional key-value pairs attached to the log record
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public func notice(_ msg: String,
                       metadata: [String: String] = [:],
                       file: StaticString = #fileID,
                       function: StaticString = #function,
                       line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.notice("\(msg, privacy: .private)\n\(suffix)")
        emitRecord(level: .notice, msg: msg, metadata: metadata, file: file, function: function, line: line)
    }

    /// Logs an error message for error conditions and failures.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - metadata: Optional key-value pairs attached to the log record
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public func error(_ msg: String,
                      metadata: [String: String] = [:],
                      file: StaticString = #fileID,
                      function: StaticString = #function,
                      line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.error("\(msg, privacy: .private)\n\(suffix)")
        emitRecord(level: .error, msg: msg, metadata: metadata, file: file, function: function, line: line)
    }
    
    // MARK: - Timer/Performance Measurement
    
    /// Starts a performance measurement interval that can be ended manually.
    /// Use this for complex scenarios where you need fine-grained control over timing.
    /// - Parameter name: A unique name for this measurement interval
    /// - Returns: OSSignpostIntervalState that must be passed to endInterval()
    /// - Note: Always pair with endInterval() to complete the measurement
    public func startInterval(_ name: StaticString) -> OSSignpostIntervalState {
        let intervalId = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: intervalId)
        return state
    }
    
    /// Ends a performance measurement interval started with startInterval().
    /// - Parameters:
    ///   - name: The name of the interval (must exactly match the name used in startInterval)
    ///   - state: The OSSignpostIntervalState returned from the corresponding startInterval() call
    public func endInterval(_ name: StaticString, state: OSSignpostIntervalState) {
        signposter.endInterval(name, state)
    }
    
    /// Measures the execution time of a synchronous closure.
    /// This is the recommended way to measure performance for most use cases.
    /// - Parameters:
    ///   - name: A descriptive name for this measurement
    ///   - operation: The closure whose execution time will be measured
    /// - Returns: The result returned by the operation closure
    /// - Throws: Re-throws any error thrown by the operation closure
    public func measure<T>(_ name: StaticString, operation: () throws -> T) rethrows -> T {
        let intervalId = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: intervalId)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            signposter.endInterval(name, state)
            info("📊 \(name) completed in \(String(format: "%.2f", duration * 1000))ms")
        }
        
        return try operation()
    }
    
    /// Measures the execution time of an asynchronous closure.
    /// Perfect for measuring async/await operations and Task execution times.
    /// - Parameters:
    ///   - name: A descriptive name for this measurement
    ///   - operation: The async closure whose execution time will be measured
    /// - Returns: The result returned by the operation closure
    /// - Throws: Re-throws any error thrown by the operation closure
    public func measureAsync<T>(_ name: StaticString, operation: () async throws -> T) async rethrows -> T {
        let intervalId = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: intervalId)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            signposter.endInterval(name, state)
            info("📊 \(name) completed in \(String(format: "%.2f", duration * 1000))ms")
        }
        
        return try await operation()
    }
    
    /// Emits an instant signpost event marker.
    /// Useful for marking specific points in time during execution for debugging and profiling.
    /// - Parameters:
    ///   - name: A descriptive name for this event
    ///   - message: Optional additional information about the event
    public func event(_ name: StaticString, _ message: String = "") {
        if message.isEmpty {
            signposter.emitEvent(name)
        } else {
            signposter.emitEvent(name, "\(message, privacy: .private)")
        }
    }
}
