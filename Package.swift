// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "PlutoSwiftSDK",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PlutoSwiftSDK",
            targets: ["PlutoSwiftSDK"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PlutoSwiftSDK",
            dependencies: ["ProverBinary"],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .binaryTarget(
            name: "ProverBinary",
            path: "PlutoProver.xcframework"
        ),
        .testTarget(
            name: "PlutoSwiftSDKTests",
            dependencies: ["PlutoSwiftSDK"]),
    ]
)
