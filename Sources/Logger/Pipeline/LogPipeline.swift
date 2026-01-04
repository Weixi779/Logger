import Foundation

final class LogPipeline: @unchecked Sendable {
    static let shared = LogPipeline()
    
    private var configuration = LoggerConfiguration()
    private var hasBootstrapped = false
    
    private init() {}
    
    // Bootstrap should be called once during app startup.
    func bootstrap(_ configuration: LoggerConfiguration) {
        guard !hasBootstrapped else {
            return
        }
        self.configuration = configuration
        hasBootstrapped = true
    }
    
    func currentConfiguration() -> LoggerConfiguration {
        configuration
    }
    
    func emit(_ record: LogRecord) {
        let exporter = configuration.exporter
        let redactor = configuration.redactor
        let redactionPolicy = configuration.redactionPolicy
        
        let output: LogRecord
        if let redactor, redactionPolicy.shouldRedact() {
            output = redactor.redact(record)
        } else {
            output = record
        }
        
        exporter?.export(output)
    }

    #if DEBUG
    func resetForTesting() {
        configuration = LoggerConfiguration()
        hasBootstrapped = false
    }
    #endif
}
