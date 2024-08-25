import XCTest
@testable import WebcamStreamer

final class WebcamStreamerTests: XCTestCase {
    func testConfigurationInitialization() {
        XCTAssertNoThrow(try Configuration(host: "localhost", port: 8080, captureSessionPreset: .medium, frameRate: 30.0, jpegCompressionQuality: 0.8))
        
        XCTAssertThrowsError(try Configuration(host: "", port: 8080, captureSessionPreset: .medium, frameRate: 30.0, jpegCompressionQuality: 0.8)) { error in
            XCTAssertEqual(error as? ConfigurationError, .invalidHost)
        }
        
        XCTAssertThrowsError(try Configuration(host: "localhost", port: 0, captureSessionPreset: .medium, frameRate: 30.0, jpegCompressionQuality: 0.8)) { error in
            XCTAssertEqual(error as? ConfigurationError, .invalidPort)
        }
        
        XCTAssertThrowsError(try Configuration(host: "localhost", port: 8080, captureSessionPreset: .medium, frameRate: 0, jpegCompressionQuality: 0.8)) { error in
            XCTAssertEqual(error as? ConfigurationError, .invalidFrameRate)
        }
        
        XCTAssertThrowsError(try Configuration(host: "localhost", port: 8080, captureSessionPreset: .medium, frameRate: 30.0, jpegCompressionQuality: 1.1)) { error in
            XCTAssertEqual(error as? ConfigurationError, .invalidJpegCompressionQuality)
        }
    }
    
    func testLoggerLevels() {
        let expectation = self.expectation(description: "Log messages should be called")
        expectation.expectedFulfillmentCount = 5
        
        class TestLogger: LoggerProtocol {
            static func log(_ level: LogLevel, _ message: String, file: String, function: String, line: Int) {
                // In a real test, you might want to verify the log level and message content
                expectation.fulfill()
            }
        }
        
        TestLogger.debug("Debug message")
        TestLogger.info("Info message")
        TestLogger.warning("Warning message")
        TestLogger.error("Error message")
        TestLogger.critical("Critical message")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWebcamStreamerInitialization() {
        let config = try! Configuration(host: "localhost", port: 8080, captureSessionPreset: .medium, frameRate: 30.0, jpegCompressionQuality: 0.8)
        let streamer = WebcamStreamer(config: config)
        
        XCTAssertNotNil(streamer)
    }
    
    // Add more tests for WebcamStreamer, HTTPServer, and other components as needed
}