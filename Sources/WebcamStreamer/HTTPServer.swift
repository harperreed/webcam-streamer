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
    }

    func start() {
        server["/"] = { _ in
            self.logger.info("Received request for home page")
            return .ok(.html(self.htmlContent))
        }

        server["/stream"] = { _ in
            self.logger.info("Received request for stream")
            return .raw(200, "OK", ["Content-Type": "multipart/x-mixed-replace; boundary=frame"]) { writer in
                do {
                    while self.isRunning {
                        if let imageData = self.streamer.getCurrentImage() {
                            do {
                                try writer.write(Data("--frame\r\n".utf8))
                                try writer.write(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
                                try writer.write(imageData)
                                try writer.write(Data("\r\n".utf8))
                                self.logger.info("Frame sent successfully")
                            } catch {
                                if let nsError = error as NSError?, nsError.domain == NSPOSIXErrorDomain && nsError.code == 32 {
                                    self.logger.info("Client disconnected")
                                    return
                                } else {
                                    self.logger.error("Error writing frame: \(error.localizedDescription)")
                                    throw error
                                }
                            }
                        } else {
                            self.logger.error("No image data available")
                        }
                        Thread.sleep(forTimeInterval: 1.0 / self.config.frameRate)
                    }
                } catch {
                    self.logger.error("Streaming ended: \(error.localizedDescription)")
                }
            }
        }

        do {
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