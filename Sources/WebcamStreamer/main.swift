import Foundation
import Dispatch
import Swifter
import ArgumentParser
import AVFoundation

/// Command-line interface for WebcamStreamer
struct WebcamStreamerCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "webcam-streamer",
        abstract: "A command-line tool for streaming webcam video over HTTP."
    )

    @Option(name: .long, help: "The host to bind the server to.")
    var host: String = "localhost"

    @Option(name: .short, help: "The port to run the server on.")
    var port: UInt16 = 8080

    @Option(name: .long, help: "The JPEG compression quality (0.0 to 1.0).")
    var jpegQuality: Double = 0.8

    @Option(name: .long, help: "The frame rate for video streaming.")
    var frameRate: Double = 30.0

    @Flag(name: .long, help: "Enable verbose logging.")
    var verbose: Bool = false

    private let logger = Logger.self

    mutating func run() throws {
        setupLogging()
        logger.info("Starting WebcamStreamer")

        do {
            let config = try createConfiguration()
            logger.debug("Configuration: \(config)")

            let selectedCamera = try selectCamera()
            logger.info("Selected camera: \(selectedCamera.localizedName)")

            let streamer = try createStreamer(with: config, camera: selectedCamera)
            let server = HTTPServer(streamer: streamer, config: config, logger: logger)

            logger.info("Starting capture and server")
            try streamer.startCapture()
            try server.start()
        } catch {
            logger.error("Error: \(error.localizedDescription)")
            throw error
        }
    }

    private func setupLogging() {
        if verbose {
            // Enable more verbose logging
            // This is a placeholder. In a real implementation, you would configure the logger to be more verbose.
            logger.debug("Verbose logging enabled")
        }
    }

    private func createConfiguration() throws -> Configuration {
        do {
            return try Configuration(
                host: host,
                port: port,
                captureSessionPreset: .medium,
                frameRate: frameRate,
                jpegCompressionQuality: CGFloat(jpegQuality)
            )
        } catch {
            logger.error("Failed to create configuration: \(error.localizedDescription)")
            throw error
        }
    }

    private func selectCamera() throws -> AVCaptureDevice {
        let availableCameras = WebcamStreamer.getAvailableCameras()

        guard !availableCameras.isEmpty else {
            logger.error("No cameras detected.")
            throw WebcamStreamerError.noCamerasAvailable
        }

        if availableCameras.count == 1 {
            logger.info("Only one camera available. Selecting it automatically.")
            return availableCameras[0]
        }

        print("Available cameras:")
        for (index, camera) in availableCameras.enumerated() {
            print("\(index + 1). \(camera.localizedName)")
        }

        var selection: Int?
        while selection == nil {
            print("Enter the number of the camera you want to use (1-\(availableCameras.count)): ", terminator: "")
            if let input = readLine(), let number = Int(input), (1...availableCameras.count).contains(number) {
                selection = number - 1
            } else {
                print("Invalid selection. Please try again.")
            }
        }

        guard let index = selection else {
            logger.error("Camera selection failed.")
            throw WebcamStreamerError.cameraSelectionFailed
        }

        return availableCameras[index]
    }

    private func createStreamer(with config: Configuration, camera: AVCaptureDevice) throws -> WebcamStreamer {
        let streamer = WebcamStreamer(config: config, logger: logger)
        do {
            try streamer.setupCaptureSession(withDevice: camera)
            return streamer
        } catch {
            logger.error("Failed to set up capture session: \(error.localizedDescription)")
            throw error
        }
    }
}

/// Custom error types for WebcamStreamer
enum WebcamStreamerError: Error, CustomStringConvertible {
    case noCamerasAvailable
    case cameraSelectionFailed

    var description: String {
        switch self {
        case .noCamerasAvailable:
            return "No cameras are available on this system."
        case .cameraSelectionFailed:
            return "Failed to select a camera."
        }
    }
}

// Run the CLI
do {
    var cli = try WebcamStreamerCLI.parseAsRoot()
    try cli.run()
} catch {
    WebcamStreamerCLI.exit(withError: error)
}
