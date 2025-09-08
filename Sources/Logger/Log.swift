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
}
