// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "CaveModules",
	platforms: [.macOS(.v15), .iOS(.v17)],
	products: [
		.library(name: "CaveDomain", targets: ["CaveDomain"]),
		.library(name: "CaveMapEngine", targets: ["CaveMapEngine"]),
		.library(name: "CaveGameplay", targets: ["CaveGameplay"])
	],
	targets: [
		.target(name: "CaveDomain"),
		.target(name: "CaveMapEngine", dependencies: ["CaveDomain"]),
		.target(name: "CaveGameplay", dependencies: ["CaveDomain"]),
		.testTarget(name: "CaveDomainTests", dependencies: ["CaveDomain"]),
		.testTarget(name: "CaveMapEngineTests", dependencies: ["CaveMapEngine", "CaveDomain"]),
		.testTarget(name: "CaveGameplayTests", dependencies: ["CaveGameplay", "CaveDomain"])
	]
)
