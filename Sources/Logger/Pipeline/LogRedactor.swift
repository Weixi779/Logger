import Foundation

/// Scrubs sensitive data from log records.
public protocol LogRedactor {
    var policy: RedactionPolicy { get }
    func redact(_ record: LogRecord) -> LogRecord
}

public extension LogRedactor {
    var policy: RedactionPolicy { .always }
}

/// Controls when a redactor is applied.
public enum RedactionPolicy {
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
