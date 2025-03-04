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
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("include")
            ],
            cxxSettings: [
                .headerSearchPath("."),
                .headerSearchPath("include")
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-Xcc", "-I./Sources/PlutoSwiftSDK",
                    "-import-objc-header", "Sources/PlutoSwiftSDK/PlutoSwiftSDK-Bridging-Header.h"
                ])
            ],
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
