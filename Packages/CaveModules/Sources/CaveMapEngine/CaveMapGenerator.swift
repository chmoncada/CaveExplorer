import CaveDomain
import Foundation

public struct CaveMapGenerator: Sendable {
	public init() {}

	public func generate(config: CaveConfig) -> CaveMapGraph {
		var builder = MapBuilder(config: config)
		return builder.build()
	}
}

private struct MapBuilder {
	private var config: CaveConfig
	private var random: SeededRandomNumberGenerator
	private var nextNodeID = 0
	private var nodes: [Int: CaveMapNode] = [:]
	private var happyDepth: Int

	init(config: CaveConfig) {
		self.config = config
		let seed = config.randomSeed ?? UInt64.random(in: UInt64.min...UInt64.max)
		self.random = SeededRandomNumberGenerator(seed: seed)
		self.happyDepth = Int.random(in: config.minimumHappyDepth...config.maxDepth, using: &random)
	}

	mutating func build() -> CaveMapGraph {
		let rootID = createNode(depth: 0, kind: .corridor, childNodeIDs: [])
		let firstNodeID = buildBranch(depth: 1, canContainHappy: true)
		let rootNode = CaveMapNode(id: rootID, depth: 0, kind: .corridor, childNodeIDs: [firstNodeID])
		nodes[rootID] = rootNode

		return CaveMapGraph(rootNodeID: rootID, nodes: nodes)
	}

	private mutating func buildBranch(depth: Int, canContainHappy: Bool) -> Int {
		if canContainHappy && depth == happyDepth {
			return createEnding(depth: depth, outcome: .escapeTreasurePortal)
		}

		if depth >= config.maxDepth {
			return createEnding(depth: depth, outcome: randomDeadlyOutcome())
		}

		if !canContainHappy && shouldTerminateEarly(at: depth) {
			return createEnding(depth: depth, outcome: randomDeadlyOutcome())
		}

		let optionCount = Int.random(in: config.minBranchOptions...config.maxBranchOptions, using: &random)
		let happyPathIndex = canContainHappy ? Int.random(in: 0..<optionCount, using: &random) : nil
		var children: [Int] = []
		children.reserveCapacity(optionCount)

		for index in 0..<optionCount {
			let childCanContainHappy = canContainHappy && index == happyPathIndex
			let childID = buildBranch(depth: depth + 1, canContainHappy: childCanContainHappy)
			children.append(childID)
		}

		return createNode(depth: depth, kind: .junction(optionCount: optionCount), childNodeIDs: children)
	}

	private mutating func createEnding(depth: Int, outcome: CaveOutcome) -> Int {
		createNode(depth: depth, kind: .ending(outcome), childNodeIDs: [])
	}

	private mutating func createNode(depth: Int, kind: CaveNodeKind, childNodeIDs: [Int]) -> Int {
		let nodeID = nextNodeID
		nextNodeID += 1
		nodes[nodeID] = CaveMapNode(id: nodeID, depth: depth, kind: kind, childNodeIDs: childNodeIDs)
		return nodeID
	}

	private mutating func shouldTerminateEarly(at depth: Int) -> Bool {
		guard depth >= 2 else { return false }
		let probability = 0.30
		let roll = Double.random(in: 0...1, using: &random)
		return roll < probability
	}

	private mutating func randomDeadlyOutcome() -> CaveOutcome {
		let deadlyOutcomes: [CaveOutcome] = [.lostInDarkness, .monsterAttack, .fatalFall, .cursedTreasure]
		let randomIndex = Int.random(in: deadlyOutcomes.indices, using: &random)
		return deadlyOutcomes[randomIndex]
	}
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
	private var state: UInt64

	init(seed: UInt64) {
		self.state = seed == 0 ? 0x123456789ABCDEF : seed
	}

	mutating func next() -> UInt64 {
		state &+= 0x9E3779B97F4A7C15
		var value = state
		value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
		value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
		return value ^ (value >> 31)
	}
}
