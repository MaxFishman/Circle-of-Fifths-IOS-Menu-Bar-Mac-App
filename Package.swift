// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CircleOfFifthsMenuBarApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CircleOfFifthsMenuBarApp",
            targets: ["CircleOfFifthsMenuBarApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CircleOfFifthsMenuBarApp",
            path: "Sources/CircleOfFifthsMenuBarApp"
        )
    ]
)
