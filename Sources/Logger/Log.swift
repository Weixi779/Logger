import Foundation

/// A convenient static interface for logging and performance measurement.
/// 
/// Provides static methods for quick logging without needing to create Logger instances.
/// All logging is done using the standard category and the app's bundle identifier as subsystem.
public enum Log {
    private static let standard = Logger(logCategory: .standard)

    /// Logs a debug message using the standard logger.
    /// Debug logs are typically not persisted in release builds.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public static func debug(_ msg: String,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: Int = #line) {
        standard.debug(msg, file: file, function: function, line: line)
    }

    /// Logs an informational message using the standard logger.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public static func info(_ msg: String,
                            file: StaticString = #fileID,
                            function: StaticString = #function,
                            line: Int = #line) {
        standard.info(msg, file: file, function: function, line: line)
    }

    /// Logs a notice message for significant events that are not errors.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public static func notice(_ msg: String,
                              file: StaticString = #fileID,
                              function: StaticString = #function,
                              line: Int = #line) {
        standard.notice(msg, file: file, function: function, line: line)
    }

    /// Logs an error message for error conditions and failures.
    /// - Parameters:
    ///   - msg: The message to log
    ///   - file: The file where the log is called (automatically captured)
    ///   - function: The function where the log is called (automatically captured)
    ///   - line: The line number where the log is called (automatically captured)
    public static func error(_ msg: String,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: Int = #line) {
        standard.error(msg, file: file, function: function, line: line)
    }
    
    // MARK: - Performance Measurement
    
    /// Measures the execution time of a synchronous closure using the standard logger.
    /// This is the recommended way to measure performance for most use cases.
    /// - Parameters:
    ///   - name: A descriptive name for this measurement
    ///   - operation: The closure whose execution time will be measured
    /// - Returns: The result returned by the operation closure
    /// - Throws: Re-throws any error thrown by the operation closure
    public static func measure<T>(_ name: StaticString, operation: () throws -> T) rethrows -> T {
        return try standard.measure(name, operation: operation)
    }
    
    /// Measures the execution time of an asynchronous closure using the standard logger.
    /// Perfect for measuring async/await operations and Task execution times.
    /// - Parameters:
    ///   - name: A descriptive name for this measurement
    ///   - operation: The async closure whose execution time will be measured
    /// - Returns: The result returned by the operation closure
    /// - Throws: Re-throws any error thrown by the operation closure
    public static func measureAsync<T>(_ name: StaticString, operation: () async throws -> T) async rethrows -> T {
        return try await standard.measureAsync(name, operation: operation)
    }
    
    /// Emits an instant signpost event marker using the standard logger.
    /// Useful for marking specific points in time during execution for debugging and profiling.
    /// - Parameters:
    ///   - name: A descriptive name for this event
    ///   - message: Optional additional information about the event
    public static func event(_ name: StaticString, _ message: String = "") {
        standard.event(name, message)
    }
}
