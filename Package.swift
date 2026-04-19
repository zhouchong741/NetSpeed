// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NetSpeed",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "NetSpeedCore",
            targets: ["NetSpeedCore"]
        ),
        .executable(
            name: "NetSpeed",
            targets: ["NetSpeed"]
        ),
    ],
    targets: [
        .target(
            name: "NetSpeedCore",
            path: "Sources/NetSpeedCore"
        ),
        .executableTarget(
            name: "NetSpeed",
            dependencies: ["NetSpeedCore"],
            path: "Sources/NetSpeed"
        ),
        .testTarget(
            name: "NetSpeedTests",
            dependencies: ["NetSpeedCore"],
            swiftSettings: [
                .unsafeFlags([
                    "-F",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                ]),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker",
                    "-rpath",
                    "-Xlinker",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker",
                    "-rpath",
                    "-Xlinker",
                    "/Library/Developer/CommandLineTools/Library/Developer/usr/lib",
                ]),
            ]
        ),
    ]
)
