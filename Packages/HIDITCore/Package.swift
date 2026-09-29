// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HIDITCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HIDITCore", targets: ["HIDITCore"]),
    ],
    targets: [
        .target(name: "HIDITCore"),
        .testTarget(name: "HIDITCoreTests", dependencies: ["HIDITCore"]),
    ]
)
