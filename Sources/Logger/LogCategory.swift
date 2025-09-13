import Foundation

/// Predefined categories for organizing logs by functional area.
/// 
/// LogCategory provides a set of common categories to help organize logs
/// by their functional purpose. Each category maps to a string value that
/// will be used in the logging system.
/// 
/// You can also create Logger instances with custom string categories if
/// these predefined ones don't meet your needs.
public enum LogCategory: String {
    /// General application logs that don't fit into specific categories
    case standard = "Standard"
    
    /// Network-related logs including API calls, connectivity, and data transfer
    case network  = "Network"
}