// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "EasyTODO",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "EasyTODO", targets: ["EasyTODO"])
    ],
    targets: [
        .executableTarget(
            name: "EasyTODO",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "EasyTODOTests",
            dependencies: ["EasyTODO"]
        )
    ]
)
