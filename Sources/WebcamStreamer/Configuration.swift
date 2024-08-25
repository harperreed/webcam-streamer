import AVFoundation

struct Configuration {
    let port: UInt16
    let captureSessionPreset: AVCaptureSession.Preset
    let frameRate: Double
    
    static let `default` = Configuration(
        port: 8080,
        captureSessionPreset: .medium,
        frameRate: 30.0
    )
}