import os
import OSLog
import Foundation

/// A logging utility built on top of Apple's unified logging system (os.Logger) with performance measurement capabilities.
/// 
/// Logger provides structured logging with automatic source context and performance measurement using OSSignposter.
/// It supports multiple log levels and can be used for both development debugging and production monitoring.
public struct Logger: Sendable {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app"
    private let logger: os.Logger
    private let signposter: OSSignposter

    /// Creates a Logger instance with a custom category string.
    /// - Parameter category: The category name for this logger instance
    public init(category: String) {
        self.logger = .init(subsystem: Self.subsystem, category: category)
        self.signposter = OSSignposter(logger: self.logger)
    }
    /// Creates a Logger instance using a predefined LogCategory.
    /// - Parameter logCategory: A predefined category from LogCategory enum
    public init(logCategory: LogCategory) {
        self.logger = .init(subsystem: Self.subsystem, category: logCategory.rawValue)
        self.signposter = OSSignposter(logger: self.logger)
    }

    private static func context(_ file: StaticString,
                                _ function: StaticString,
                                _ line: Int) -> String {
        "[\(file):\(line)] \(function)"
    }

    /// Logs an informational message.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public func info(_ msg: String,
                     file: StaticString = #fileID,
                     function: StaticString = #function,
                     line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.info("\(msg, privacy: .private)\n\(suffix)")
    }

    /// Logs a debug message. Debug logs are typically not persisted in release builds.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public func debug(_ msg: String,
                      file: StaticString = #fileID,
                      function: StaticString = #function,
                      line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.debug("\(msg, privacy: .private)\n\(suffix)")
    }

    /// Logs a notice message for significant events that are not errors.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public func notice(_ msg: String,
                       file: StaticString = #fileID,
                       function: StaticString = #function,
                       line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.notice("\(msg, privacy: .private)\n\(suffix)")
    }

    /// Logs an error message for error conditions and failures.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public func error(_ msg: String,
                      file: StaticString = #fileID,
                      function: StaticString = #function,
                      line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.error("\(msg, privacy: .private)\n\(suffix)")
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
        defer {
            signposter.endInterval(name, state)
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
        defer {
            signposter.endInterval(name, state)
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
