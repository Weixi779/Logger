import Foundation
import os

/// Global entry point for the logging system.
public enum LoggerSystem {
    private static let engine = LogSystemEngine()
    
    /// Sets up optional global log processing.
    ///
    /// Local logging is always enabled. Setup replaces the current redactors and exporters.
    public static func setup(exporters: [LogExporter] = [],
                             redactors: [LogRedactor] = []) {
        engine.setup(
            exporters: exporters,
            redactors: redactors
        )
    }
    
    /// Convenience setup for the common single-exporter case.
    public static func setup(exporter: LogExporter,
                             redactors: [LogRedactor] = []) {
        setup(exporters: [exporter], redactors: redactors)
    }
    
    public static func addExporter(_ exporter: LogExporter) {
        engine.addExporters([exporter])
    }
    
    public static func addExporters(_ exporters: [LogExporter]) {
        engine.addExporters(exporters)
    }
    
    public static func addRedactor(_ redactor: LogRedactor) {
        engine.addRedactors([redactor])
    }
    
    public static func addRedactors(_ redactors: [LogRedactor]) {
        engine.addRedactors(redactors)
    }
    
    public static func removeAllExporters() {
        engine.removeAllExporters()
    }
    
    public static func removeAllRedactors() {
        engine.removeAllRedactors()
    }
    
    static func emit(_ record: LogRecord) {
        engine.emit(record)
    }

    #if DEBUG
    static func resetForTesting() {
        engine.resetForTesting()
    }
    #endif
}

private final class LogSystemEngine: @unchecked Sendable {
    private let state = Locked(LogSystemState())
    private let localSink = LocalLogSink()
    
    func setup(exporters: [LogExporter],
               redactors: [LogRedactor]) {
        state.withValue {
            $0.exporters = exporters
            $0.redactors = redactors
        }
    }
    
    func addExporters(_ exporters: [LogExporter]) {
        state.withValue {
            $0.exporters.append(contentsOf: exporters)
        }
    }
    
    func addRedactors(_ redactors: [LogRedactor]) {
        state.withValue {
            $0.redactors.append(contentsOf: redactors)
        }
    }
    
    func removeAllExporters() {
        state.withValue {
            $0.exporters.removeAll()
        }
    }
    
    func removeAllRedactors() {
        state.withValue {
            $0.redactors.removeAll()
        }
    }
    
    func emit(_ record: LogRecord) {
        let components = state.read { $0 }
        var output = record
        for redactor in components.redactors where redactor.policy.shouldRedact() {
            output = redactor.redact(output)
        }
        
        localSink.emit(output)
        for exporter in components.exporters {
            exporter.export(output)
        }
    }

    #if DEBUG
    func resetForTesting() {
        state.withValue {
            $0 = LogSystemState()
        }
    }
    #endif
}

private struct LogSystemState {
    var exporters: [LogExporter] = []
    var redactors: [LogRedactor] = []
}

private final class Locked<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()
    
    init(_ value: Value) {
        self.value = value
    }
    
    func read<T>(_ body: (Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(value)
    }
    
    func withValue<T>(_ body: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&value)
    }
}

private struct LocalLogSink {
    func emit(_ record: LogRecord) {
        let logger = os.Logger(subsystem: record.subsystem, category: record.category)
        let message = "\(record.message)\n\(context(record))"
        
        switch record.level {
        case .debug:
            logger.debug("\(message, privacy: .private)")
        case .info, .all:
            logger.info("\(message, privacy: .private)")
        case .notice:
            logger.notice("\(message, privacy: .private)")
        case .error:
            logger.error("\(message, privacy: .private)")
        case .fault:
            logger.fault("\(message, privacy: .private)")
        }
    }
    
    private func context(_ record: LogRecord) -> String {
        "[\(record.file):\(record.line)] \(record.function)"
    }
}
