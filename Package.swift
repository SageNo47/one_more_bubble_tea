// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MilkTeaPet",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MilkTeaPet",
            path: "Sources/MilkTeaPet",
            resources: [.process("Resources")]
        )
    ]
)
