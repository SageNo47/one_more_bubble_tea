// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MilkTeaPet",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "MilkTeaDomain", targets: ["MilkTeaDomain"]),
        .library(name: "MilkTeaPersistence", targets: ["MilkTeaPersistence"]),
        .executable(name: "MilkTeaPet", targets: ["MilkTeaPet"])
    ],
    targets: [
        .target(
            name: "MilkTeaDomain",
            path: "Sources/MilkTeaDomain"
        ),
        .target(
            name: "MilkTeaPersistence",
            dependencies: ["MilkTeaDomain"],
            path: "Sources/MilkTeaPersistence"
        ),
        .executableTarget(
            name: "MilkTeaPet",
            dependencies: ["MilkTeaDomain", "MilkTeaPersistence"],
            path: "Sources/MilkTeaPet",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "MilkTeaDomainTests",
            dependencies: ["MilkTeaDomain"],
            path: "Tests/MilkTeaDomainTests"
        ),
        .testTarget(
            name: "MilkTeaPersistenceTests",
            dependencies: ["MilkTeaDomain", "MilkTeaPersistence"],
            path: "Tests/MilkTeaPersistenceTests"
        ),
        .testTarget(
            name: "MilkTeaPetTests",
            dependencies: ["MilkTeaDomain", "MilkTeaPet"],
            path: "Tests/MilkTeaPetTests"
        )
    ]
)
