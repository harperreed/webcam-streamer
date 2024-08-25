import os.log

/// Enum defining log levels
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

/// Enum defining log levels
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

/// Protocol defining the interface for a logger
protocol LoggerProtocol {
    static func log(_ level: LogLevel, _ message: String, file: String, function: String, line: Int)
}

/// Logger struct implementing the LoggerProtocol
struct Logger: LoggerProtocol {
    private static let logger = OSLog(subsystem: "com.webcamstreamer", category: "WebcamStreamer")
    
    /// Log a message with the specified level and context
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    static func log(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(level.rawValue)] \(fileName):\(line) - \(function) - \(message)"
        
        switch level {
        case .debug:
            os_log(.debug, log: logger, "%{public}@", logMessage)
        case .info:
            os_log(.info, log: logger, "%{public}@", logMessage)
        case .warning:
            os_log(.default, log: logger, "⚠️ %{public}@", logMessage)
        case .error, .critical:
            os_log(.error, log: logger, "🛑 %{public}@", logMessage)
        }
    }
}

extension Logger {
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }
    
    static func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message, file: file, function: function, line: line)
    }
}

#if DEBUG
extension Logger {
    /// Log a debug message with additional context (only in DEBUG builds)
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    static func debugWithContext(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(LogLevel.debug.rawValue)] \(fileName):\(line) - \(function) - \(message)"
        os_log(.debug, log: logger, "%{public}@", logMessage)
    }
}
#endif