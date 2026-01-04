import Foundation

// Exporters are expected to be configured at startup and remain read-only.

/// Receives structured log records for remote export.
public protocol LogExporter {
    func export(_ record: LogRecord)
}
