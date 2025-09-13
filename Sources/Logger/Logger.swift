import os
import OSLog
import Foundation

public struct Logger: Sendable {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app"
    private let logger: os.Logger
    private let signposter: OSSignposter

    public init(category: String) {
        self.logger = .init(subsystem: Self.subsystem, category: category)
        self.signposter = OSSignposter(logger: self.logger)
    }
    public init(logCategory: LogCategory) {
        self.logger = .init(subsystem: Self.subsystem, category: logCategory.rawValue)
        self.signposter = OSSignposter(logger: self.logger)
    }

    private static func context(_ file: StaticString,
                                _ function: StaticString,
                                _ line: Int) -> String {
        "[\(file):\(line)] \(function)"
    }

    public func info(_ msg: String,
                     file: StaticString = #fileID,
                     function: StaticString = #function,
                     line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.info("\(msg, privacy: .private)\n\(suffix)")
    }

    public func debug(_ msg: String,
                      file: StaticString = #fileID,
                      function: StaticString = #function,
                      line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.debug("\(msg, privacy: .private)\n\(suffix)")
    }

    public func notice(_ msg: String,
                       file: StaticString = #fileID,
                       function: StaticString = #function,
                       line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.notice("\(msg, privacy: .private)\n\(suffix)")
    }

    public func error(_ msg: String,
                      file: StaticString = #fileID,
                      function: StaticString = #function,
                      line: Int = #line) {
        let suffix = Logger.context(file, function, line)
        logger.error("\(msg, privacy: .private)\n\(suffix)")
    }
    
    // MARK: - Timer/Performance Measurement
    
    /// Start a performance measurement interval
    /// - Parameter name: The name of the interval
    /// - Returns: OSSignpostIntervalState for ending the interval
    public func startInterval(_ name: StaticString) -> OSSignpostIntervalState {
        let intervalId = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: intervalId)
        return state
    }
    
    /// End a performance measurement interval
    /// - Parameters:
    ///   - name: The name of the interval (must match startInterval)
    ///   - state: The OSSignpostIntervalState returned from startInterval
    public func endInterval(_ name: StaticString, state: OSSignpostIntervalState) {
        signposter.endInterval(name, state)
    }
    
    /// Measure the execution time of a closure and log the result
    /// - Parameters:
    ///   - name: The name for this measurement
    ///   - operation: The closure to measure
    /// - Returns: The result of the operation
    public func measure<T>(_ name: StaticString, operation: () throws -> T) rethrows -> T {
        let intervalId = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: intervalId)
        defer {
            signposter.endInterval(name, state)
        }
        return try operation()
    }
    
    /// Measure the execution time of an async closure and log the result
    /// - Parameters:
    ///   - name: The name for this measurement
    ///   - operation: The async closure to measure
    /// - Returns: The result of the operation
    public func measureAsync<T>(_ name: StaticString, operation: () async throws -> T) async rethrows -> T {
        let intervalId = signposter.makeSignpostID()
        let state = signposter.beginInterval(name, id: intervalId)
        defer {
            signposter.endInterval(name, state)
        }
        return try await operation()
    }
    
    /// Emit a signpost event (instant marker)
    /// - Parameters:
    ///   - name: The event name
    ///   - message: Optional message
    public func event(_ name: StaticString, _ message: String = "") {
        if message.isEmpty {
            signposter.emitEvent(name)
        } else {
            signposter.emitEvent(name, "\(message, privacy: .private)")
        }
    }
}
