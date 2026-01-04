# Logger

A comprehensive Swift logging library built on Apple's unified logging system with performance measurement and log export capabilities.

## Features

- 🪵 **Structured Logging** - Built on `os.Logger` with automatic source context
- ⚡ **Performance Measurement** - Integrated `OSSignposter` for timing operations  
- 📊 **Log Export** - Retrieve and export logs using `OSLogStore`
- 🎯 **Category-Based Loggers** - Create loggers per feature or component
- 🔒 **Privacy-Aware** - Automatic privacy protection for log messages
- 🧵 **Thread-Safe** - Safe for concurrent use across multiple threads
- 📱 **iOS 15+** - Modern iOS, macOS, tvOS, and watchOS support

## Requirements

- **iOS 15.0+** / **macOS 12.0+** / **tvOS 15.0+** / **watchOS 8.0+**
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add Logger to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/Logger.git", from: "1.0.0")
]
```

## Quick Start

### Basic Logging

```swift
import Logger

let logger = Logger(logCategory: .standard)
logger.debug("App started")
logger.info("User logged in successfully") 
logger.notice("Network connection established")
logger.error("Failed to load data: \(error)")

// Instance interface (for custom categories)
let networkLogger = Logger(category: "Network")
networkLogger.info("API request started")

// Predefined categories
let featureLogger = Logger(logCategory: .network)
featureLogger.debug("Connection established")
```

### Performance Measurement

```swift
import Logger

let logger = Logger(logCategory: .standard)

// Measure synchronous operations
let result = logger.measure("database_query") {
    return database.fetchUsers()
}

// Measure asynchronous operations  
let data = await logger.measureAsync("api_request") {
    return await apiClient.getData()
}

// Manual timing for complex scenarios
let logger = Logger(category: "Performance")
let state = logger.startInterval("complex_operation")
// ... complex logic ...
logger.endInterval("complex_operation", state: state)

// Event markers
logger.event("checkpoint_reached", "Processing 50% complete")
```

### Log Export & Analysis

```swift
import Logger

// Export logs for debug analysis
do {
    let logger = Logger(logCategory: .standard)
    let logStore = try LogStore()
    
    // Get logs from last hour
    let since = Date().addingTimeInterval(-3600)
    let logs = try logStore.getLogs(since: since, levels: [.error, .fault])
    
    // Export as JSON for programmatic processing
    let jsonData = try logStore.exportLogsAsJSON(since: since)
    
    // Export as text for human reading
    let textData = try logStore.exportLogsAsText(since: since)
    
    // Share or save logs
    let activityVC = UIActivityViewController(activityItems: [textData], applicationActivities: nil)
    present(activityVC, animated: true)
    
} catch {
    Logger(logCategory: .standard).error("Failed to export logs: \(error)")
}
```

## Log Levels

| Level   | Description | Persistence |
|---------|-------------|-------------|
| `debug` | Detailed debugging information | Not persisted in Release |
| `info`  | General informational messages | Persisted |
| `notice` | Significant events (not errors) | Persisted |
| `error` | Error conditions and failures | Persisted |
| `fault` | Critical system errors | Always persisted |

## Categories

### Predefined Categories

```swift
// Use predefined categories for common use cases
let standardLogger = Logger(logCategory: .standard)  // General app logs
let networkLogger = Logger(logCategory: .network)    // Network operations
```

### Custom Categories

```swift
// Create custom categories for specific components
let databaseLogger = Logger(category: "Database")
let authLogger = Logger(category: "Authentication")
let cacheLogger = Logger(category: "Cache")
```

## Performance Analysis

Logger integrates with **Instruments** for visual performance analysis:

1. **Run your app with Instruments**
2. **Select the "Logging" template**
3. **Use signpost intervals** created by `measure()` methods
4. **Analyze timing data** in the Timeline view

Example Instruments view:
```
Timeline: Your App Process
├── Database Query     [■■■■░░░░░░] 45ms
├── API Request        [░░■■■■■■░░] 120ms  
└── Image Processing   [░░░░░■■■░░] 80ms
```

## Advanced Usage

### Filtering Logs

```swift
let logStore = try LogStore()

// Filter by time range and levels
let errorLogs = try logStore.getLogs(
    since: Date().addingTimeInterval(-86400), // Last 24 hours
    until: Date(),
    levels: [.error, .fault]
)

// Export specific categories (system automatically filters by subsystem)
let jsonLogs = try logStore.exportLogsAsJSON(
    since: startTime,
    levels: [.info, .notice, .error]
)
```

### Async/Await Support

```swift
let logger = Logger(logCategory: .standard)

// Perfect for measuring async operations
let user = await logger.measureAsync("user_login") {
    try await authService.login(credentials)
}

// Measure Task execution
await logger.measureAsync("background_processing") {
    await Task.detached {
        await processLargeDataSet()
    }.value
}
```

### Error Handling Best Practices

```swift
func performNetworkRequest() async {
    let logger = Logger(logCategory: .network)
    
    logger.info("Starting API request")
    
    do {
        let result = await logger.measureAsync("api_call") {
            try await apiClient.fetchData()
        }
        logger.info("API request completed successfully")
        return result
    } catch {
        logger.error("API request failed: \(error)")
        throw error
    }
}
```

## Integration Examples

### SwiftUI Integration

```swift
import SwiftUI
import Logger

struct ContentView: View {
    @State private var logs: [LogEntry] = []
    private let logger = Logger(logCategory: .standard)
    
    var body: some View {
        NavigationView {
            List(logs, id: \.timestamp) { entry in
                LogRowView(entry: entry)
            }
            .navigationTitle("Debug Logs")
            .toolbar {
                Button("Export") {
                    exportLogs()
                }
            }
        }
        .task {
            loadLogs()
        }
    }
    
    private func loadLogs() {
        Task {
            do {
                let logStore = try LogStore()
                let since = Date().addingTimeInterval(-3600) // Last hour
                logs = try logStore.getLogs(since: since)
            } catch {
                logger.error("Failed to load logs: \(error)")
            }
        }
    }
    
    private func exportLogs() {
        // Implementation for exporting logs
    }
}
```

### Debug Menu Integration

```swift
#if DEBUG
struct DebugMenu: View {
    @State private var showingLogExport = false
    private let logger = Logger(logCategory: .standard)
    
    var body: some View {
        List {
            Button("Export Logs") {
                showingLogExport = true
            }
            
            Button("Clear Cache") {
                logger.measure("cache_clear") {
                    CacheManager.shared.clearAll()
                }
            }
        }
        .sheet(isPresented: $showingLogExport) {
            LogExportView()
        }
    }
}
#endif
```

## Best Practices

### 1. Choose Appropriate Log Levels
```swift
// ✅ Good
let logger = Logger(logCategory: .standard)
logger.debug("Entering function with parameters: \(params)")  // Development only
logger.info("User completed onboarding")                       // Important events  
logger.error("Network request failed: \(error)")              // Actionable errors

// ❌ Avoid
logger.info("Loop iteration \(i)")                            // Too verbose
logger.error("User tapped button")                            // Not an error
```

### 2. Use Meaningful Categories
```swift
// ✅ Good
let authLogger = Logger(category: "Authentication") 
let paymentLogger = Logger(category: "Payment")

// ❌ Avoid  
let logger1 = Logger(category: "Stuff")
let logger2 = Logger(category: "Things")
```

### 3. Measure Performance Strategically
```swift
// ✅ Good - Measure significant operations
let logger = Logger(category: "Performance")
let result = logger.measure("image_processing") {
    return processImage(image)
}

// ❌ Avoid - Don't measure trivial operations
let sum = logger.measure("addition") { 
    return a + b  // Too fast to be meaningful
}
```

### 4. Handle Export Errors Gracefully
```swift
// ✅ Good
func exportDebugLogs() {
    do {
        let logStore = try LogStore()
        let logs = try logStore.exportLogsAsText(since: yesterday)
        shareDebugInfo(logs)
    } catch {
        // Fallback: create manual debug info
        let fallbackInfo = createFallbackDebugInfo()
        shareDebugInfo(fallbackInfo)
    }
}
```

## Troubleshooting

### Common Issues

**Q: Logs not appearing in export**
- A: Ensure you're using the correct time range and log levels
- A: Check that logs were created with the same subsystem (bundle identifier)

**Q: Performance measurements not showing in Instruments**  
- A: Make sure you're using the Logging template in Instruments
- A: Verify signposts are enabled in the Instruments settings

**Q: Build errors with LogStore**
- A: Ensure your minimum deployment target is iOS 15.0+
- A: Import both `OSLog` and `Logger` modules

**Q: Tests failing in CI/CD**
- A: LogStore requires actual device/simulator, may not work in test environments
- A: Use conditional compilation for testing environments

### Debug Tips

```swift
#if DEBUG
// Enable verbose logging in debug builds
Logger(logCategory: .standard).debug("Detailed debug information here")

// Export logs for debugging
if ProcessInfo.processInfo.arguments.contains("--export-logs") {
    exportLogsForDebugging()
}
#endif
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on Apple's excellent `os.Logger` and `OSSignposter` frameworks
- Inspired by the need for simple, powerful logging in iOS development
- Thanks to the Swift community for feedback and contributions
