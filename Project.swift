import ProjectDescription

let project = Project(
    name: "CaveExplorer",
    packages: [
        .remote(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            requirement: .upToNextMajor(from: "0.57.1")
        )
    ],
    targets: [
        .target(
            name: "CaveExplorer",
            destinations: .macOS,
            product: .app,
            bundleId: "com.charlesmoncada.caveExplorer",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["CaveExplorer/Sources/**"],
            resources: [],
            dependencies: [
                .package(product: "SwiftLintBuildToolPlugin", type: .plugin)
            ]
        ),
        .target(
            name: "CaveExplorerTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.charlesmoncada.caveExplorerTests",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["CaveExplorer/Tests/**"],
            resources: [],
            dependencies: [.target(name: "CaveExplorer")]
        ),
    ]
)
