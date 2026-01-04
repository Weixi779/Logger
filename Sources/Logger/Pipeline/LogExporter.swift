import Foundation

/// Receives structured log records for remote export.
public protocol LogExporter: Sendable {
    func export(_ record: LogRecord)
}
