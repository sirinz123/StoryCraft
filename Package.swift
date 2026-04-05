// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "SwiftTaskApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "App", targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(
            url: "https://github.com/stephencelis/SQLite.swift.git",
            from: "0.15.5",
            traits: ["SQLiteSwiftCSQLite"]
        ),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "Crypto", package: "swift-crypto"),
            ],
            path: "Sources/App"
        )
    ]
)