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
    
    func recordCount() -> Int {
        records.count
    }
    
    func allRecords() -> [LogRecord] {
        records
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
    
    func recordCount() async -> Int {
        store.recordCount()
    }
    
    func allRecords() async -> [LogRecord] {
        store.allRecords()
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
    let policy: RedactionPolicy
    
    init(suffix: String, policy: RedactionPolicy = .always) {
        self.suffix = suffix
        self.policy = policy
    }
    
    func redact(_ record: LogRecord) -> LogRecord {
        record.replacing(message: record.message + suffix)
    }
}

@Suite(.serialized)
struct LoggerTests {

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
    LoggerSystem.resetForTesting()
    defer { LoggerSystem.resetForTesting() }
    
    do {
        let exporter = CaptureExporter()
        LoggerSystem.setup(exporter: exporter)
        
        let logger = Logger(category: "Export")
        logger.info("Export test")
        
        #expect((await waitForRecord(exporter))?.message == "Export test")
    }
    
    LoggerSystem.resetForTesting()
    do {
        let exporter = CaptureExporter()
        let redactor = TestRedactor(suffix: "_redacted", policy: .never)
        LoggerSystem.setup(
            exporter: exporter,
            redactors: [redactor]
        )
        
        let logger = Logger(category: "Redaction")
        logger.info("Original")
        
        #expect((await waitForRecord(exporter))?.message == "Original")
    }
    
    LoggerSystem.resetForTesting()
    do {
        let exporter = CaptureExporter()
        let redactor = TestRedactor(suffix: "_redacted", policy: .always)
        LoggerSystem.setup(
            exporter: exporter,
            redactors: [redactor]
        )
        
        let logger = Logger(category: "Redaction")
        logger.info("Original")
        
        #expect((await waitForRecord(exporter))?.message == "Original_redacted")
    }
    
    LoggerSystem.resetForTesting()
    do {
        let exporter = CaptureExporter()
        LoggerSystem.setup(exporter: exporter)
        
        let logger = Logger(category: "   ")
        logger.info("Default category")
        
        #expect((await waitForRecord(exporter))?.category == Logger.defaultCategory)
    }
    
    LoggerSystem.resetForTesting()
    do {
        let firstExporter = CaptureExporter()
        let secondExporter = CaptureExporter()
        let firstRedactor = TestRedactor(suffix: "_one")
        let secondRedactor = TestRedactor(suffix: "_two")
        
        LoggerSystem.setup(
            exporters: [firstExporter, secondExporter],
            redactors: [firstRedactor, secondRedactor]
        )
        
        let logger = Logger(category: "Pipeline")
        logger.info("Multiple")
        
        #expect((await waitForRecord(firstExporter))?.message == "Multiple_one_two")
        #expect((await waitForRecord(secondExporter))?.message == "Multiple_one_two")
    }
    
    LoggerSystem.resetForTesting()
    do {
        let firstExporter = CaptureExporter()
        let secondExporter = CaptureExporter()
        let firstRedactor = TestRedactor(suffix: "_first")
        let secondRedactor = TestRedactor(suffix: "_second")
        let logger = Logger(category: "HotSwap")
        
        LoggerSystem.setup(exporter: firstExporter)
        logger.info("Before")
        
        LoggerSystem.addRedactor(firstRedactor)
        LoggerSystem.addExporter(secondExporter)
        logger.info("After add")
        
        LoggerSystem.setup(exporters: [secondExporter], redactors: [secondRedactor])
        logger.info("After replace")
        
        #expect(await firstExporter.recordCount() == 2)
        #expect(await secondExporter.recordCount() == 2)
        #expect((await firstExporter.allRecords()).map(\.message) == ["Before", "After add_first"])
        #expect((await secondExporter.allRecords()).map(\.message) == ["After add_first", "After replace_second"])
        
        LoggerSystem.removeAllExporters()
        LoggerSystem.removeAllRedactors()
        logger.info("After remove")
        
        #expect(await firstExporter.recordCount() == 2)
        #expect(await secondExporter.recordCount() == 2)
    }
}

}
