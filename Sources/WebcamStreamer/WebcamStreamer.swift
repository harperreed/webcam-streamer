import Foundation
import AVFoundation
import Cocoa

/// Protocol defining the interface for a webcam streamer
protocol WebcamStreamerProtocol: AnyObject {
    func startCapture() throws
    func stopCapture()
    func getCurrentImage() -> Data?
    func recoverFromError(_ error: Error)
}

/// Custom error types for WebcamStreamer
enum WebcamStreamerError: Error {
    case deviceSetupFailed
    case captureSessionSetupFailed
    case captureStartFailed
}

/// Main class responsible for capturing and processing webcam data
class WebcamStreamer: NSObject, WebcamStreamerProtocol {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentImageData: Data?
    private let imageQueue = DispatchQueue(label: "com.webcamstreamer.imageQueue")
    private let processingQueue = DispatchQueue(label: "com.webcamstreamer.processingQueue", qos: .userInitiated)
    private let config: Configuration
    private let logger: LoggerProtocol.Type
    private var isRecovering = false
    private var isRecovering = false

    /// Initializes a new WebcamStreamer instance
    /// - Parameters:
    ///   - config: The configuration to use for the streamer
    ///   - logger: The logger to use for logging messages
    init(config: Configuration = .default, logger: LoggerProtocol.Type = Logger.self) {
        self.config = config
        self.logger = logger
        super.init()
        self.logger.debug("WebcamStreamer initialized with config: \(config)")
    }

    /// Sets up the capture session with the specified device
    /// - Parameter device: The AVCaptureDevice to use for capturing
    /// - Throws: WebcamStreamerError if setup fails
    func setupCaptureSession(withDevice device: AVCaptureDevice) throws {
        logger.debug("Setting up capture session with device: \(device.localizedName)")
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = config.captureSessionPreset

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard captureSession?.canAddInput(input) == true else {
                logger.error("Cannot add video input to capture session")
                throw WebcamStreamerError.captureSessionSetupFailed
            }
            captureSession?.addInput(input)

            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: processingQueue)
            guard let videoOutput = videoOutput, captureSession?.canAddOutput(videoOutput) == true else {
                logger.error("Cannot add video output to capture session")
                throw WebcamStreamerError.captureSessionSetupFailed
            }
            captureSession?.addOutput(videoOutput)

            logger.info("Capture session setup completed successfully")
        } catch {
            logger.error("Error setting up capture session: \(error.localizedDescription)")
            throw WebcamStreamerError.deviceSetupFailed
        }
    }

    /// Returns an array of available camera devices
    /// - Returns: An array of AVCaptureDevice objects representing available cameras
    static func getAvailableCameras() -> [AVCaptureDevice] {
        var deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]

        if #available(macOS 14.0, *) {
            deviceTypes.append(contentsOf: [.external, .continuityCamera])
        }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )

        return discoverySession.devices
    }

    /// Starts the capture session
    /// - Throws: WebcamStreamerError if starting capture fails
    func startCapture() throws {
        logger.debug("Starting capture")
        guard let captureSession = captureSession else {
            logger.error("Capture session not set up")
            throw WebcamStreamerError.captureStartFailed
        }
        
        if !captureSession.isRunning {
            captureSession.startRunning()
            if captureSession.isRunning {
                logger.info("Capture started")
            } else {
                logger.error("Failed to start capture session")
                throw WebcamStreamerError.captureStartFailed
            }
        } else {
            logger.warning("Capture session already running")
        }
    }

    /// Stops the capture session
    func stopCapture() {
        logger.debug("Stopping capture")
        captureSession?.stopRunning()
        logger.info("Capture stopped")
    }

    /// Returns the current image data
    /// - Returns: The current image data as Data?, or nil if no image is available
    func getCurrentImage() -> Data? {
        return imageQueue.sync { currentImageData }
    }

    /// Attempts to recover from an error
    /// - Parameter error: The error to recover from
    func recoverFromError(_ error: Error) {
        guard !isRecovering else {
            logger.warning("Already attempting to recover from an error")
            return
        }

        isRecovering = true
        logger.info("Attempting to recover from error: \(error.localizedDescription)")

        // Implement recovery logic here
        // For example, you might try to reinitialize the capture session
        do {
            if let device = AVCaptureDevice.default(for: .video) {
                try setupCaptureSession(withDevice: device)
                try startCapture()
                logger.info("Successfully recovered from error")
            } else {
                logger.error("No video device available for recovery")
            }
        } catch {
            logger.error("Failed to recover from error: \(error.localizedDescription)")
        }

        isRecovering = false
    }
}

extension WebcamStreamer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        logger.debug("Processing new frame")
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            logger.error("Failed to get image buffer from sample buffer")
            return
        }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            logger.error("Failed to create CGImage from CIImage")
            return
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: config.jpegCompressionQuality]) else {
            logger.error("Failed to create JPEG representation")
            return
        }

        imageQueue.sync {
            currentImageData = jpegData
        }
        logger.debug("Frame processed and stored")
    }
}
