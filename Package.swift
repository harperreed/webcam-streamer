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
            resources: [.process("../Info.plist")])
    ]
)
