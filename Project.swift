import ProjectDescription

let project = Project(
    name: "FlappyBird",
    targets: [
        .target(
            name: "FlappyBird",
            destinations: .macOS,
            product: .app,
            bundleId: "io.tuist.FlappyBird",
            infoPlist: .default,
            sources: ["FlappyBird/Sources/**"],
            resources: [],
            dependencies: []
        ),
        .target(
            name: "FlappyBirdTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "io.tuist.FlappyBirdTests",
            infoPlist: .default,
            sources: ["FlappyBird/Tests/**"],
            resources: [],
            dependencies: [.target(name: "FlappyBird")]
        ),
    ]
)
