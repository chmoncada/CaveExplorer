// swift-tools-version: 6.0
import PackageDescription

let package = Package(
	name: "CaveModules",
	platforms: [.macOS(.v15), .iOS(.v17)],
	products: [
		.library(name: "CaveDomain", targets: ["CaveDomain"]),
		.library(name: "CaveMapEngine", targets: ["CaveMapEngine"])
	],
	targets: [
		.target(name: "CaveDomain"),
		.target(name: "CaveMapEngine", dependencies: ["CaveDomain"]),
		.testTarget(name: "CaveDomainTests", dependencies: ["CaveDomain"]),
		.testTarget(name: "CaveMapEngineTests", dependencies: ["CaveMapEngine", "CaveDomain"])
	]
)
