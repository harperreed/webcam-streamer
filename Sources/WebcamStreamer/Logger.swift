import os

protocol LoggerProtocol {
    static func info(_ message: String)
    static func error(_ message: String)
}

struct Logger: LoggerProtocol {
    private static let logger = OSLog(subsystem: "com.webcamstreamer", category: "WebcamStreamer")
    
    static func info(_ message: String) {
        os_log(.info, log: logger, "%{public}@", message)
    }
    
    static func error(_ message: String) {
        os_log(.error, log: logger, "%{public}@", message)
    }
}