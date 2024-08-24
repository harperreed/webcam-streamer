import Foundation
import AVFoundation
import Cocoa
import Swifter

class WebcamStreamer: NSObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var currentImageData: Data?
    private let semaphore = DispatchSemaphore(value: 1)

    override init() {
        super.init()
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(for: .video) else {
            print("No video device available")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }

            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if captureSession?.canAddOutput(videoOutput!) == true {
                captureSession?.addOutput(videoOutput!)
            }
        } catch {
            print("Error setting up capture session: \(error)")
        }
    }

    func startCapture() {
        captureSession?.startRunning()
    }

    func stopCapture() {
        captureSession?.stopRunning()
    }

    func getCurrentImage() -> Data? {
        semaphore.wait()
        defer { semaphore.signal() }
        return currentImageData
    }
}

extension WebcamStreamer: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [:]) else { return }

        semaphore.wait()
        currentImageData = jpegData
        semaphore.signal()
    }
}

class HTTPServer {
    private let streamer: WebcamStreamer
    private let server = HttpServer()

    init(streamer: WebcamStreamer) {
        self.streamer = streamer
    }

    func start() {
        server["/"] = { _ in
            print("Received request for home page")
            return .ok(.html(self.htmlContent))
        }

        server["/stream"] = { _ in
            print("Received request for stream")
            return .raw(200, "OK", ["Content-Type": "multipart/x-mixed-replace; boundary=frame"]) { writer in
                do {
                    while true {
                        if let imageData = self.streamer.getCurrentImage() {
                            do {
                                try writer.write(Data("--frame\r\n".utf8))
                                try writer.write(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
                                try writer.write(imageData)
                                try writer.write(Data("\r\n".utf8))
                                print("Frame sent successfully")
                            } catch {
                                if let nsError = error as NSError?, nsError.domain == NSPOSIXErrorDomain && nsError.code == 32 {
                                    print("Client disconnected")
                                    return
                                } else {
                                    print("Error writing frame: \(error)")
                                    throw error
                                }
                            }
                        } else {
                            print("No image data available")
                        }
                        Thread.sleep(forTimeInterval: 0.03) // Approx 30 fps
                    }
                } catch {
                    print("Streaming ended: \(error)")
                }
            }
        }

        do {
            try server.start(8080)
            print("Server running on http://localhost:8080")
            RunLoop.main.run()
        } catch {
            print("Error starting server: \(error)")
        }
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

let streamer = WebcamStreamer()
streamer.startCapture()

let server = HTTPServer(streamer: streamer)
server.start()
