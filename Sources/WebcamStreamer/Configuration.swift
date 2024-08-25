import AVFoundation

/// Error types for Configuration
enum ConfigurationError: Error {
    case invalidHost
    case invalidPort
    case invalidFrameRate
    case invalidJpegCompressionQuality
}

/// Error types for Configuration
enum ConfigurationError: Error {
    case invalidHost
    case invalidPort
    case invalidFrameRate
    case invalidJpegCompressionQuality
}

/// Configuration struct for WebcamStreamer settings
struct Configuration {
    /// The host address for the HTTP server
    let host: String
    
    /// The port number for the HTTP server
    let port: UInt16
    
    /// The capture session preset for video quality
    let captureSessionPreset: AVCaptureSession.Preset
    
    /// The frame rate for video streaming
    let frameRate: Double
    
    /// The JPEG compression quality (0.0 to 1.0)
    let jpegCompressionQuality: CGFloat
    
    /// Default configuration
    static let `default` = Configuration(
        host: "localhost",
        port: 8080,
        captureSessionPreset: .medium,
        frameRate: 30.0,
        jpegCompressionQuality: 0.8
    )
    
    /// Initializes a new Configuration instance
    /// - Parameters:
    ///   - host: The host address for the HTTP server
    ///   - port: The port number for the HTTP server
    ///   - captureSessionPreset: The capture session preset for video quality
    ///   - frameRate: The frame rate for video streaming
    ///   - jpegCompressionQuality: The JPEG compression quality (0.0 to 1.0)
    /// - Throws: ConfigurationError if any parameter is invalid
    init(host: String, port: UInt16, captureSessionPreset: AVCaptureSession.Preset, frameRate: Double, jpegCompressionQuality: CGFloat) throws {
        guard !host.isEmpty else {
            throw ConfigurationError.invalidHost
        }
        
        guard port > 0 else {
            throw ConfigurationError.invalidPort
        }
        
        guard frameRate > 0 else {
            throw ConfigurationError.invalidFrameRate
        }
        
        guard (0.0...1.0).contains(jpegCompressionQuality) else {
            throw ConfigurationError.invalidJpegCompressionQuality
        }
        
        self.host = host
        self.port = port
        self.captureSessionPreset = captureSessionPreset
        self.frameRate = frameRate
        self.jpegCompressionQuality = jpegCompressionQuality
    }
}