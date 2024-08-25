import Foundation
import Swifter

protocol HTTPServerProtocol: AnyObject {
    func start()
    func stop()
}

class HTTPServer: HTTPServerProtocol {
    private let streamer: WebcamStreamerProtocol
    private let server: HttpServer
    private let config: Configuration
    private var isRunning = false
    private let logger: LoggerProtocol.Type

    init(streamer: WebcamStreamerProtocol, server: HttpServer = HttpServer(), config: Configuration, logger: LoggerProtocol.Type = Logger.self) {
        self.streamer = streamer
        self.server = server
        self.config = config
        self.logger = logger
        logger.info("Initializing HTTPServer with configuration: port=\(config.port), frameRate=\(config.frameRate)")
    }

    func start() {
        logger.info("Setting up server routes...")
        server["/"] = { _ in
            self.logger.info("Received request for home page")
            return .ok(.html(self.htmlContent))
        }

        server["/stream"] = { _ in
            self.logger.info("Received request for stream")
            return .raw(200, "OK", ["Content-Type": "multipart/x-mixed-replace; boundary=frame"]) { writer in
                do {
                    var frameCount = 0
                    while self.isRunning {
                        if let imageData = self.streamer.getCurrentImage() {
                            do {
                                try writer.write(Data("--frame\r\n".utf8))
                                try writer.write(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
                                try writer.write(imageData)
                                try writer.write(Data("\r\n".utf8))
                                frameCount += 1
                                self.logger.info("Frame #\(frameCount) sent successfully. Size: \(imageData.count) bytes")
                            } catch {
                                if let nsError = error as NSError?, nsError.domain == NSPOSIXErrorDomain && nsError.code == 32 {
                                    self.logger.info("Client disconnected after \(frameCount) frames")
                                    return
                                } else {
                                    self.logger.error("Error writing frame #\(frameCount): \(error.localizedDescription)")
                                    throw error
                                }
                            }
                        } else {
                            self.logger.error("No image data available for frame #\(frameCount + 1)")
                        }
                        Thread.sleep(forTimeInterval: 1.0 / self.config.frameRate)
                    }
                } catch {
                    self.logger.error("Streaming ended: \(error.localizedDescription)")
                }
            }
        }

        logger.info("Server routes set up successfully")

        do {
            logger.info("Starting server on port \(config.port)...")
            try server.start(config.port)
            isRunning = true
            logger.info("Server running on http://localhost:\(config.port)")
            while isRunning {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            }
        } catch {
            logger.error("Error starting server: \(error.localizedDescription)")
        }
    }

    func stop() {
        logger.info("Stopping server...")
        isRunning = false
        server.stop()
        streamer.stopCapture()
        logger.info("Server stopped")
    }

    private var htmlContent: String {
        return """
        <!DOCTYPE html>
        <html>
            <head>
                <title>Webcam Streamer</title>
            </head>
            <body>
                <h1>Webcam Stream</h1>
                <img src="/stream" alt="Webcam Stream">
            </body>
        </html>
        """
    }
}