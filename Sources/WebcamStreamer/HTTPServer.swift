import Foundation
import Swifter

/// Protocol defining the interface for an HTTP server
protocol HTTPServerProtocol: AnyObject {
    func start() throws
    func stop()
}

/// HTTP server class responsible for handling webcam streaming requests
class HTTPServer: HTTPServerProtocol {
    private let streamer: WebcamStreamerProtocol
    private let server: HttpServer
    private let config: Configuration
    private var isRunning = false
    private let logger: LoggerProtocol.Type
    private let streamQueue = DispatchQueue(label: "com.webcamstreamer.streamQueue", qos: .userInteractive)
    private var activeConnections = Set<HttpServerIO.Socket>()
    private let connectionQueue = DispatchQueue(label: "com.webcamstreamer.connectionQueue")
    private var activeConnections = Set<HttpServerIO.Socket>()
    private let connectionQueue = DispatchQueue(label: "com.webcamstreamer.connectionQueue")

    /// Initializes a new HTTPServer instance
    /// - Parameters:
    ///   - streamer: The WebcamStreamerProtocol instance to use for streaming
    ///   - server: The HttpServer instance to use (default is a new HttpServer)
    ///   - config: The configuration to use for the server
    ///   - logger: The logger to use for logging messages
    init(streamer: WebcamStreamerProtocol, server: HttpServer = HttpServer(), config: Configuration, logger: LoggerProtocol.Type = Logger.self) {
        self.streamer = streamer
        self.server = server
        self.config = config
        self.logger = logger
        logger.debug("HTTPServer initialized with config: \(config)")
    }

    /// Starts the HTTP server
    /// - Throws: An error if the server fails to start
    func start() throws {
        logger.debug("Setting up server routes")
        setupRoutes()

        logger.debug("Starting server")
        do {
            try server.start(config.port, forceIPv4: false, priority: .default, address: config.host)
            isRunning = true
            logger.info("Server running on http://\(config.host):\(config.port)")
            
            // Set up signal handling for graceful shutdown
            setupSignalHandling()
            
            while isRunning {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
            }
        } catch {
            logger.error("Error starting server: \(error.localizedDescription)")
            throw error
        }
    }

    /// Stops the HTTP server
    func stop() {
        logger.debug("Stopping server")
        isRunning = false
        
        // Close all active connections
        connectionQueue.sync {
            for socket in activeConnections {
                socket.close()
            }
            activeConnections.removeAll()
        }
        
        server.stop()
        streamer.stopCapture()
        logger.info("Server stopped")
    }

    /// Sets up the routes for the HTTP server
    private func setupRoutes() {
        server["/"] = { _ in
            self.logger.debug("Received request for home page")
            return .ok(.html(self.htmlContent))
        }

        server["/stream"] = { socket in
            self.logger.debug("Received request for stream")
            self.connectionQueue.sync {
                self.activeConnections.insert(socket)
            }
            return .raw(200, "OK", ["Content-Type": "multipart/x-mixed-replace; boundary=frame"]) { writer in
                self.handleStreamRequest(writer: writer, socket: socket)
            }
        }
    }

    /// Handles the streaming request
    /// - Parameters:
    ///   - writer: The HttpResponseBodyWriter to write the stream data to
    ///   - socket: The socket associated with the connection
    private func handleStreamRequest(writer: HttpResponseBodyWriter, socket: HttpServerIO.Socket) {
        streamQueue.async {
            do {
                while self.isRunning && !socket.isClosed {
                    if let imageData = self.streamer.getCurrentImage() {
                        do {
                            try writer.write(Data("--frame\r\n".utf8))
                            try writer.write(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
                            try writer.write(imageData)
                            try writer.write(Data("\r\n".utf8))
                            self.logger.debug("Frame sent successfully")
                        } catch {
                            if let nsError = error as NSError?, nsError.domain == NSPOSIXErrorDomain && nsError.code == 32 {
                                self.logger.info("Client disconnected")
                                break
                            } else {
                                self.logger.error("Error writing frame: \(error.localizedDescription)")
                                throw error
                            }
                        }
                    } else {
                        self.logger.warning("No image data available")
                    }
                    Thread.sleep(forTimeInterval: 1.0 / self.config.frameRate)
                }
            } catch {
                self.logger.error("Streaming ended: \(error.localizedDescription)")
            }
            
            self.connectionQueue.sync {
                self.activeConnections.remove(socket)
            }
        }
    }

    /// Sets up signal handling for graceful shutdown
    private func setupSignalHandling() {
        signal(SIGINT) { _ in
            print("\nReceived SIGINT. Shutting down...")
            self.stop()
            exit(0)
        }
        
        signal(SIGTERM) { _ in
            print("\nReceived SIGTERM. Shutting down...")
            self.stop()
            exit(0)
        }
    }

    /// The HTML content for the home page
    private var htmlContent: String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Webcam Streamer</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    background-color: #f0f0f0;
                    margin: 0;
                    padding: 20px;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                }
                .container {
                    background-color: white;
                    border-radius: 10px;
                    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                    padding: 20px;
                    text-align: center;
                }
                h1 {
                    color: #333;
                    margin-bottom: 20px;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border: 1px solid #ddd;
                    border-radius: 5px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Webcam Stream</h1>
                <img src="/stream" alt="Webcam Stream">
            </div>
        </body>
        </html>
        """
    }
}