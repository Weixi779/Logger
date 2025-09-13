import Foundation

public enum Log {
    private static let standard = Logger(logCategory: .standard)

    public static func debug(_ msg: String,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: Int = #line) {
        standard.debug(msg, file: file, function: function, line: line)
    }

    public static func info(_ msg: String,
                            file: StaticString = #fileID,
                            function: StaticString = #function,
                            line: Int = #line) {
        standard.info(msg, file: file, function: function, line: line)
    }

    public static func notice(_ msg: String,
                              file: StaticString = #fileID,
                              function: StaticString = #function,
                              line: Int = #line) {
        standard.notice(msg, file: file, function: function, line: line)
    }

    public static func error(_ msg: String,
                             file: StaticString = #fileID,
                             function: StaticString = #function,
                             line: Int = #line) {
        standard.error(msg, file: file, function: function, line: line)
    }
    
    // MARK: - Performance Measurement
    
    /// Measure the execution time of a closure
    /// - Parameters:
    ///   - name: The name for this measurement
    ///   - operation: The closure to measure
    /// - Returns: The result of the operation
    public static func measure<T>(_ name: StaticString, operation: () throws -> T) rethrows -> T {
        return try standard.measure(name, operation: operation)
    }
    
    /// Measure the execution time of an async closure
    /// - Parameters:
    ///   - name: The name for this measurement
    ///   - operation: The async closure to measure
    /// - Returns: The result of the operation
    public static func measureAsync<T>(_ name: StaticString, operation: () async throws -> T) async rethrows -> T {
        return try await standard.measureAsync(name, operation: operation)
    }
    
    /// Emit a signpost event (instant marker)
    /// - Parameters:
    ///   - name: The event name
    ///   - message: Optional message
    public static func event(_ name: StaticString, _ message: String = "") {
        standard.event(name, message)
    }
}
