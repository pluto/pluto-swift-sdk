// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "PlutoSwiftSDK",
    platforms: [
        .iOS(.v17_2)  // Minimum iOS version supported
    ],
    products: [
        .library(
            name: "PlutoSwiftSDK",
            targets: ["PlutoSwiftSDK"]
        )
    ],
    targets: [
        .target(
            name: "PlutoSwiftSDK",
            path: "Sources"  // Path to your source code
        ),
        .testTarget(
            name: "PlutoSwiftSDKTests",
            dependencies: ["PlutoSwiftSDK"],
            path: "Tests"  // Path to your test files
        )
    ],
    swiftLanguageVersions: [.v5]
)
