import Foundation
import Dispatch
import Swifter

let config = Configuration.default
let logger = Logger.self

logger.info("Starting WebcamStreamer application...")
logger.info("Configuration: port=\(config.port), captureSessionPreset=\(config.captureSessionPreset), frameRate=\(config.frameRate)")

let streamer = WebcamStreamer(config: config, logger: logger)
let server = HTTPServer(streamer: streamer, config: config, logger: logger)

// Set up signal handling for graceful shutdown
let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigintSrc.setEventHandler {
    logger.info("\nReceived SIGINT. Initiating graceful shutdown...")
    server.stop()
    logger.info("WebcamStreamer application shutdown complete.")
    exit(0)
}
sigintSrc.resume()

logger.info("Starting webcam capture...")
streamer.startCapture()

logger.info("Starting HTTP server...")
server.start()

logger.info("WebcamStreamer application is now running. Press Ctrl+C to stop.")
