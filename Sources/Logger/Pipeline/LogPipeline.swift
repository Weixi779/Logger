import Foundation

final class LogPipeline: @unchecked Sendable {
    static let shared = LogPipeline()
    
    private let lock = NSLock()
    private var configuration = LoggerConfiguration()
    
    private init() {}
    
    func bootstrap(_ configuration: LoggerConfiguration) {
        lock.lock()
        self.configuration = configuration
        lock.unlock()
    }
    
    func currentConfiguration() -> LoggerConfiguration {
        lock.lock()
        let current = configuration
        lock.unlock()
        return current
    }
    
    func emit(_ record: LogRecord) {
        lock.lock()
        let exporter = configuration.exporter
        let redactor = configuration.redactor
        let redactionPolicy = configuration.redactionPolicy
        lock.unlock()
        
        let output: LogRecord
        if let redactor, redactionPolicy.shouldRedact() {
            output = redactor.redact(record)
        } else {
            output = record
        }
        
        exporter?.export(output)
    }
}
