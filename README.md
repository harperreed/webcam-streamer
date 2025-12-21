# Webcam Streamer 📹

Welcome to the Webcam Streamer project repository! This README will guide you through the project overview, how to use it, and some technical information.

<img width="504" alt="image" src="https://github.com/harperreed/assets/eaab63df-4a0b-4c3e-b9af-a9d9f9480a4e">

---

## Summary of Project 📑

**Webcam Streamer** is a macOS application built with Swift. It captures video using the system's webcam and streams it over HTTP. It is useful for creating simple, real-time webcam streams accessible through a web browser.

---

## How to Use 🚀

1. **Clone the Repository**

   ```bash
   git clone https://github.com/harperreed/webcam-streamer.git
   cd webcam-streamer
   ```

2. **Build the Project**

   Use `Makefile` targets to build and run the project:
   
   - To build:
     ```bash
     make build
     ```
   
   - To run:
     ```bash
     make run
     ```

3. **Access the Stream**

   Once the server is running, open your web browser and navigate to `http://localhost:8080` to view the webcam stream.

4. **Additional Commands**
   
   - To build for release:
     ```bash
     make release
     ```
   
   - To clean build artifacts:
     ```bash
     make clean
     ```
   
   - To install the release binary:
     ```bash
     sudo make install
     ```
   
   - To uninstall:
     ```bash
     sudo make uninstall
     ```

---

## Technical Information 🛠️

#### Directory/File Tree

```plaintext
webcam-streamer/
├── Info.plist
├── Makefile
├── Package.resolved
├── Package.swift
├── README.md
├── Sources
│   └── WebcamStreamer
│       ├── Configuration.swift
│       ├── HTTPServer.swift
│       ├── Logger.swift
│       ├── WebcamStreamer.swift
│       └── main.swift
```

#### Dependencies

The project relies on the **Swifter** library for the HTTP server:

- **Swifter**
  - Repository: `https://github.com/httpswift/swifter.git`
  - Version: `1.5.0`

This dependency is included in the `Package.swift` file and resolved in `Package.resolved`.

#### Key Files and Content

- **Info.plist**
  - Contains metadata for the app, including camera usage description and device type.
  
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSCameraUsageDescription</key>
    <string>This app needs access to the camera to stream video.</string>
    <key>NSCameraUseContinuityCameraDeviceType</key>
    <true/>
</dict>
</plist>
```

- **Makefile**
  - Contains make targets for building, running, cleaning, and installing/uninstalling the application.
  
```makefile
# Variables
SWIFT = swift
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
DEBUG_DIR = $(BUILD_DIR)/debug
PRODUCT_NAME = WebcamStreamer

# Targets and rules
.PHONY: all clean build run release debug

all: build

build:
	$(SWIFT) build

run: build
	$(SWIFT) run

release:
	$(SWIFT) build -c release
	@echo "Release binary is at $(RELEASE_DIR)/$(PRODUCT_NAME)"

debug:
	$(SWIFT) build -c debug
	@echo "Debug binary is at $(DEBUG_DIR)/$(PRODUCT_NAME)"

clean:
	rm -rf $(BUILD_DIR)

# Install the release binary to /usr/local/bin
install: release
	cp $(RELEASE_DIR)/$(PRODUCT_NAME) /usr/local/bin/$(PRODUCT_NAME)
	@echo "Installed $(PRODUCT_NAME) to /usr/local/bin"

# Uninstall the binary from /usr/local/bin
uninstall:
	rm -f /usr/local/bin/$(PRODUCT_NAME)
	@echo "Uninstalled $(PRODUCT_NAME) from /usr/local/bin"
```

- **Package.swift**
  - Defines the Swift package, dependencies, and the build configuration.

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "WebcamStreamer",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0"))
    ],
    targets: [
        .target(
            name: "WebcamStreamer",
            dependencies: [.product(name: "Swifter", package: "swifter")],
            resources: [.process("Info.plist")])
    ]
)
```

- **`Sources/WebcamStreamer/main.swift`**
  - Main application code that sets up the capture session and HTTP server to stream video data.

```swift
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
```

---

Enjoy your webcam streaming! If you encounter any issues or have questions, feel free to open an issue on GitHub. 🌟

Happy coding!

---

*Authored by* **`@harperreed`**
