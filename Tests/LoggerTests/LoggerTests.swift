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
    logger.warning("Warning message")
    logger.error("Error message")
}

@Test("Log static methods execute without throwing")
func testLogStaticMethods() async throws {
    Log.debug("Static debug message")
    Log.info("Static info message") 
    Log.warning("Static warning message")
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
