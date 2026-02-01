// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacAssistant",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacAssistant", targets: ["MacAssistant"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacAssistant",
            dependencies: [],
            path: "Sources/App",
            resources: [],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/App/App-Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "MacAssistantTests",
            dependencies: ["MacAssistant"],
            path: "Tests/AppTests"
        )
    ]
)
