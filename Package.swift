// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DesktopTodo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DesktopTodo", targets: ["DesktopTodo"])
    ],
    targets: [
        .executableTarget(
            name: "DesktopTodo"
        ),
        .testTarget(
            name: "DesktopTodoTests",
            dependencies: ["DesktopTodo"]
        )
    ]
)
