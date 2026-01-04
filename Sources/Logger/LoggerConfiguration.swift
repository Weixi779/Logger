import Foundation

/// Global configuration for the Logger system.
public struct LoggerConfiguration: Sendable {
    /// Optional exporter for forwarding structured log records.
    public var exporter: LogExporter?
    /// Optional redactor for scrubbing sensitive data.
    public var redactor: LogRedactor?
    /// Policy controlling when the redactor runs.
    public var redactionPolicy: RedactionPolicy
    
    public init(exporter: LogExporter? = nil,
                redactor: LogRedactor? = nil,
                redactionPolicy: RedactionPolicy = .always) {
        self.exporter = exporter
        self.redactor = redactor
        self.redactionPolicy = redactionPolicy
    }
}
