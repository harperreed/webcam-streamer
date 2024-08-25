import Foundation
import Dispatch
import Swifter
import ArgumentParser
import AVFoundation

struct WebcamStreamerCLI: ParsableCommand {
    @Option(name: .long, help: "The host to bind the server to.")
    var host: String = "localhost"

    @Option(name: .short, help: "The port to run the server on.")
    var port: UInt16 = 8080

    mutating func run() throws {
        let config = Configuration(
            host: host,
            port: port,
            captureSessionPreset: .medium,
            frameRate: 30.0
        )
        let logger = Logger.self

        let availableCameras = WebcamStreamer.getAvailableCameras()

        if availableCameras.isEmpty {
            print("No cameras detected.")
            return
        }

        let selectedCamera: AVCaptureDevice
        if availableCameras.count == 1 {
            selectedCamera = availableCameras[0]
            print("Using the only available camera: \(selectedCamera.localizedName)")
        } else {
            print("Available cameras:")
            for (index, camera) in availableCameras.enumerated() {
                print("\(index + 1). \(camera.localizedName)")
            }

            var selection: Int?
            while selection == nil {
                print("Enter the number of the camera you want to use: ", terminator: "")
                if let input = readLine(), let number = Int(input), (1...availableCameras.count).contains(number) {
                    selection = number - 1
                } else {
                    print("Invalid selection. Please try again.")
                }
            }
            selectedCamera = availableCameras[selection!]
        }

        let streamer = WebcamStreamer(config: config, logger: logger)
        streamer.setupCaptureSession(withDevice: selectedCamera)
        let server = HTTPServer(streamer: streamer, config: config, logger: logger)

        // Set up signal handling for graceful shutdown
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSrc.setEventHandler {
            print("\nReceived SIGINT. Shutting down...")
            server.stop()
            exit(0)
        }
        sigintSrc.resume()

        streamer.startCapture()
        server.start()
    }
}

WebcamStreamerCLI.main()
