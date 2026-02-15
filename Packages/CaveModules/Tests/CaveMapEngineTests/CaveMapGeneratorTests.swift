import CaveDomain
import CaveMapEngine
import XCTest

final class CaveMapGeneratorTests: XCTestCase {
	func test_generate_createsExactlyOneHappyEnding() {
		let config = CaveConfig(maxDepth: 5, randomSeed: 42)
		let graph = CaveMapGenerator().generate(config: config)
		let happyCount = graph.endingNodes.filter { node in
			if case .ending(let outcome) = node.kind {
				return outcome.isHappyEnding
			}
			return false
		}.count

		XCTAssertEqual(happyCount, 1)
	}

	func test_generate_placesHappyEndingInLastTwentyPercent() throws {
		let config = CaveConfig(maxDepth: 5, happyEndingStartPercent: 0.8, randomSeed: 19)
		let graph = CaveMapGenerator().generate(config: config)
		let happyNode = try XCTUnwrap(graph.happyEndingNode)

		XCTAssertGreaterThanOrEqual(happyNode.depth, config.minimumHappyDepth)
		XCTAssertLessThanOrEqual(happyNode.depth, config.maxDepth)
	}

	func test_generate_usesOnlyTwoOrThreeOptionsInJunctions() {
		let config = CaveConfig(maxDepth: 5, randomSeed: 77)
		let graph = CaveMapGenerator().generate(config: config)
		let junctionNodes = graph.nodes.values.filter { node in
			if case .junction = node.kind {
				return true
			}
			return false
		}

		for node in junctionNodes {
			if case .junction(let optionCount) = node.kind {
				XCTAssertTrue((2...3).contains(optionCount))
				XCTAssertEqual(node.childNodeIDs.count, optionCount)
			}
		}
	}

	func test_generate_buildsGraphWithValidChildReferences() {
		let config = CaveConfig(maxDepth: 5, randomSeed: 901)
		let graph = CaveMapGenerator().generate(config: config)

		for node in graph.nodes.values {
			for childID in node.childNodeIDs {
				XCTAssertNotNil(graph.nodes[childID])
			}
		}
	}

	func test_generate_isDeterministicWithSameSeed() {
		let config = CaveConfig(maxDepth: 5, randomSeed: 99)
		let generator = CaveMapGenerator()

		let firstGraph = generator.generate(config: config)
		let secondGraph = generator.generate(config: config)

		XCTAssertEqual(firstGraph, secondGraph)
	}
}
