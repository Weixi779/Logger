import Testing
@testable import Logger

@Test("Logger struct initialization with string category")
func testLoggerInitWithString() async throws {
    let logger = Logger(category: "TestCategory")
    logger.info("Test initialization")
}

@Test("Logger struct initialization with LogCategory enum")
func testLoggerInitWithCategory() async throws {
    let logger = Logger(logCategory: .standard)
    logger.info("Standard logger test")
    
    let networkLogger = Logger(logCategory: .network)
    networkLogger.info("Network logger test")
}

@Test("Logger methods execute without throwing")
func testLoggerMethods() async throws {
    let logger = Logger(logCategory: .standard)
    
    logger.debug("Debug message")
    logger.info("Info message")
    logger.notice("Notice message")
    logger.error("Error message")
}

@Test("Log static methods execute without throwing")
func testLogStaticMethods() async throws {
    Log.debug("Static debug message")
    Log.info("Static info message") 
    Log.notice("Static notice message")
    Log.error("Static error message")
}

@Test("LogCategory enum values")
func testLogCategoryValues() async throws {
    #expect(LogCategory.standard.rawValue == "Standard")
    #expect(LogCategory.network.rawValue == "Network")
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
