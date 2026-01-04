import Foundation

/// Scrubs sensitive data from log records.
public protocol LogRedactor: Sendable {
    func redact(_ record: LogRecord) -> LogRecord
}

/// Controls when the redactor is applied.
public enum RedactionPolicy: Sendable {
    case never
    case always
    case when(@Sendable () -> Bool)
    
    func shouldRedact() -> Bool {
        switch self {
        case .never:
            return false
        case .always:
            return true
        case let .when(condition):
            return condition()
        }
    }
}
