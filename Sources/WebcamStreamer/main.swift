import Foundation
import Dispatch
import Swifter

let config = Configuration.default
let logger = Logger.self
let streamer = WebcamStreamer(config: config, logger: logger)
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
