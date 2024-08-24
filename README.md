# Webcam Streamer 📹

Welcome to the Webcam Streamer project repository! This README will guide you through the project overview, how to use it, and some technical information.

![Uploading image.png…]()

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
├── Sources
│   └── WebcamStreamer
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

- **Makefile**
  - Contains make targets for building, running, cleaning, and installing/uninstalling the application.

- **Package.swift**
  - Defines the Swift package, dependencies, and the build configuration.

- **`Sources/WebcamStreamer/main.swift`**
  - Main application code that sets up the capture session and HTTP server to stream video data.

---

Enjoy your webcam streaming! If you encounter any issues or have questions, feel free to open an issue on GitHub. 🌟

Happy coding!

---

*Authored by* **`@harperreed`**
