import Foundation
import AVFoundation
import Cocoa

protocol WebcamStreamerProtocol: AnyObject {
    func startCapture()
    func stopCapture()
    func getCurrentImage() -> Data?
}

class WebcamStreamer: NSObject, WebcamStreamerProtocol {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentImageData: Data?
    private let imageQueue = DispatchQueue(label: "com.webcamstreamer.imageQueue")
    private let config: Configuration
    private let logger: LoggerProtocol.Type

    init(config: Configuration = .default, logger: LoggerProtocol.Type = Logger.self) {
        self.config = config
        self.logger = logger
        super.init()
        logger.info("Initializing WebcamStreamer with configuration: port=\(config.port), preset=\(config.captureSessionPreset), frameRate=\(config.frameRate)")
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        logger.info("Setting up capture session...")
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = config.captureSessionPreset
        logger.info("Capture session preset set to: \(config.captureSessionPreset)")

        var deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]

        if #available(macOS 14.0, *) {
            deviceTypes.append(contentsOf: [.external, .continuityCamera])
        }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )

        guard let device = discoverySession.devices.first else {
            logger.error("No video device available")
            return
        }
        logger.info("Video device found: \(device.localizedName)")

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard captureSession?.canAddInput(input) == true else {
                logger.error("Cannot add video input to capture session")
                return
            }
            captureSession?.addInput(input)
            logger.info("Video input added to capture session")

            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            guard let videoOutput = videoOutput, captureSession?.canAddOutput(videoOutput) == true else {
                logger.error("Cannot add video output to capture session")
                return
            }
            captureSession?.addOutput(videoOutput)

            logger.info("Video output added to capture session")
            
            logger.info("Capture session setup completed successfully")
        } catch {
            logger.error("Error setting up capture session: \(error.localizedDescription)")
        }
    }

    func startCapture() {
        logger.info("Starting capture...")
        captureSession?.startRunning()
        logger.info("Capture started")
    }

    func stopCapture() {
        logger.info("Stopping capture...")
        captureSession?.stopRunning()
        logger.info("Capture stopped")
    }

    func getCurrentImage() -> Data? {
        logger.info("Retrieving current image...")
        let image = imageQueue.sync { currentImageData }
        logger.info("Current image retrieved. Size: \(image?.count ?? 0) bytes")
        return image
    }
}

extension WebcamStreamer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
            logger.error("Failed to create JPEG representation")
            return
        }

        imageQueue.sync {
            currentImageData = jpegData
        }
        logger.info("New frame captured and processed. Size: \(jpegData.count) bytes")
    }
}
