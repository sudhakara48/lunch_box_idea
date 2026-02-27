// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LunchBoxPrep",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)  // allows `swift build` / `swift test` on macOS CI
    ],
    products: [
        .library(name: "LunchBoxPrep", targets: ["LunchBoxPrep"]),
        .executable(name: "LunchBoxPrepApp", targets: ["LunchBoxPrepApp"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/typelift/SwiftCheck.git",
            exact: "0.12.0"
        )
    ],
    targets: [
        .target(
            name: "LunchBoxPrep",
            path: "Sources/LunchBoxPrep"
        ),
        .executableTarget(
            name: "LunchBoxPrepApp",
            dependencies: ["LunchBoxPrep"],
            path: "Sources/LunchBoxPrepApp"
        ),
        .testTarget(
            name: "LunchBoxPrepTests",
            dependencies: [
                "LunchBoxPrep",
                .product(name: "SwiftCheck", package: "SwiftCheck")
            ],
            path: "Tests/LunchBoxPrepTests"
        )
    ]
)
