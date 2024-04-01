// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "webim-client-sdk-ios",
    products: [
        .library(name: "WebimClientLibrary", targets: ["WebimClientLibrary"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", "0.13.3"..<"0.13.3")
    ],
    targets: [
        .target(
            name: "WebimClientLibrary",
            dependencies: ["SQLite"],
            path: "WebimClientLibrary"
        )
    ]
)
