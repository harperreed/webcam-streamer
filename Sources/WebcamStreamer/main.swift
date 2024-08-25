import Foundation
import Dispatch

// Import the new modules
import Configuration
import Logger
import WebcamStreamer
import HTTPServer

let config = Configuration.default
let logger = Logger.self
let streamer = WebcamStreamer(config: config, logger: logger)
let server = HTTPServer(streamer: streamer, config: config, logger: logger)

// Set up signal handling for graceful shutdown
import Dispatch
let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigintSrc.setEventHandler {
    print("\nReceived SIGINT. Shutting down...")
    server.stop()
    exit(0)
}
sigintSrc.resume()

streamer.startCapture()
server.start()
