import os
import Foundation

public struct Logger: Sendable {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app"
    private let logger: os.Logger

    public init(category: String) {
        self.logger = .init(subsystem: Self.subsystem, category: category)
    }
    public init(logCategory: LogCategory) {
        self.logger = .init(subsystem: Self.subsystem, category: logCategory.rawValue)
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
}
