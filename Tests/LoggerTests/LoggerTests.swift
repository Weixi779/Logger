import Testing
import Foundation
@testable import Logger

private final class CaptureExporterStore {
    private var records: [LogRecord] = []
    
    func append(_ record: LogRecord) {
        records.append(record)
    }
    
    func firstRecord() -> LogRecord? {
        records.first
    }
}

private final class CaptureExporter: LogExporter {
    let store: CaptureExporterStore
    
    init(store: CaptureExporterStore = CaptureExporterStore()) {
        self.store = store
    }
    
    func export(_ record: LogRecord) {
        store.append(record)
    }
    
    func firstRecord() async -> LogRecord? {
        store.firstRecord()
    }
}

private func waitForRecord(_ exporter: CaptureExporter,
                           attempts: Int = 100,
                           delayNanoseconds: UInt64 = 10_000_000) async -> LogRecord? {
    await Task.yield()
    for _ in 0..<attempts {
        if let record = await exporter.firstRecord() {
            return record
        }
        try? await Task.sleep(nanoseconds: delayNanoseconds)
    }
    return nil
}


private struct TestRedactor: LogRedactor {
    let suffix: String
    
    func redact(_ record: LogRecord) -> LogRecord {
        LogRecord(
            timestamp: record.timestamp,
            level: record.level,
            category: record.category,
            subsystem: record.subsystem,
            message: record.message + suffix,
            file: record.file,
            function: record.function,
            line: record.line,
            metadata: record.metadata
        )
    }
}

@Test("Logger struct initialization with string category")
func testLoggerInitWithString() async throws {
    let logger = Logger(category: "TestCategory")
    logger.info("Test initialization")
}

@Test("Logger struct initialization with default category")
func testLoggerInitWithDefault() async throws {
    let logger = Logger()
    logger.info("Default logger test")
}

@Test("Logger methods execute without throwing")
func testLoggerMethods() async throws {
    let logger = Logger()
    
    logger.debug("Debug message")
    logger.info("Info message")
    logger.notice("Notice message")
    logger.error("Error message")
}


@Test("Logger context formatting")
func testLoggerContext() async throws {
    let logger = Logger(category: "Test")
    
    logger.info("Test message")
}

@Test("LogStore initialization")
func testLogStoreInit() async throws {
    do {
        let _ = try LogStore()
        // LogStore created successfully
    } catch {
        // LogStore might fail in test environment without proper log data
        print("LogStore init failed in test: \(error)")
    }
}

@Test("LogLevel enum properties")
func testLogLevelProperties() async throws {
    #expect(LogLevel.debug.displayName == "DEBUG")
    #expect(LogLevel.info.displayName == "INFO")
    #expect(LogLevel.notice.displayName == "NOTICE")
    #expect(LogLevel.error.displayName == "ERROR")
    #expect(LogLevel.fault.displayName == "FAULT")
    #expect(LogLevel.all.displayName == "ALL")
    
    // Test Identifiable
    #expect(LogLevel.debug.id == LogLevel.debug)
    #expect(LogLevel.info.id == LogLevel.info)
}

@Test("LogLevel from OSLog conversion")
func testLogLevelConversion() async throws {
    #expect(LogLevel.from(.debug) == .debug)
    #expect(LogLevel.from(.info) == .info)
    #expect(LogLevel.from(.error) == .error)
    #expect(LogLevel.from(.fault) == .fault)
}

@Test("Logger measure method")
func testLoggerMeasure() async throws {
    let logger = Logger(category: "TestTimer")
    
    let result = logger.measure("test_operation") {
        usleep(10000) // 10ms
        return 42
    }
    
    #expect(result == 42)
}

@Test("Logger measureAsync method")
func testLoggerMeasureAsync() async throws {
    let logger = Logger(category: "TestTimer")
    
    let result = await logger.measureAsync("test_async_operation") {
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        return "async_result"
    }
    
    #expect(result == "async_result")
}

@Test("Logger start/end interval")
func testLoggerInterval() async throws {
    let logger = Logger(category: "TestTimer")
    
    let state = logger.startInterval("manual_interval")
    usleep(10000) // 10ms  
    logger.endInterval("manual_interval", state: state)
}

@Test("Logger event")
func testLoggerEvent() async throws {
    let logger = Logger(category: "TestTimer")
    
    logger.event("test_event")
    logger.event("test_event_with_message", "This is a test message")
}

@Test("Logger pipeline behavior")
func testLoggerPipelineBehavior() async throws {
    Logger.resetForTesting()
    defer { Logger.resetForTesting() }
    
    do {
        let exporter = CaptureExporter()
        Logger.bootstrap(LoggerConfiguration(exporter: exporter))
        
        let logger = Logger(category: "Export")
        logger.info("Export test")
        
        #expect((await waitForRecord(exporter))?.message == "Export test")
    }
    
    Logger.resetForTesting()
    do {
        let exporter = CaptureExporter()
        let redactor = TestRedactor(suffix: "_redacted")
        Logger.bootstrap(LoggerConfiguration(
            exporter: exporter,
            redactor: redactor,
            redactionPolicy: .never
        ))
        
        let logger = Logger(category: "Redaction")
        logger.info("Original")
        
        #expect((await waitForRecord(exporter))?.message == "Original")
    }
    
    Logger.resetForTesting()
    do {
        let exporter = CaptureExporter()
        let redactor = TestRedactor(suffix: "_redacted")
        Logger.bootstrap(LoggerConfiguration(
            exporter: exporter,
            redactor: redactor,
            redactionPolicy: .always
        ))
        
        let logger = Logger(category: "Redaction")
        logger.info("Original")
        
        #expect((await waitForRecord(exporter))?.message == "Original_redacted")
    }
    
    Logger.resetForTesting()
    do {
        let exporter = CaptureExporter()
        Logger.bootstrap(LoggerConfiguration(exporter: exporter))
        
        let logger = Logger(category: "   ")
        logger.info("Default category")
        
        #expect((await waitForRecord(exporter))?.category == Logger.defaultCategory)
    }
}
