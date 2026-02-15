// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CaveExplorerTools",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-format.git", from: "510.1.0")
    ]
)
