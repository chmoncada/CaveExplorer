import CaveDomain
import CaveGameplay
import XCTest

final class CaveRunEngineTests: XCTestCase {
	func test_init_startsTravelingFromRootToFirstNode() {
		let graph = makeSimpleChoiceGraph()
		let config = CaveConfig(maxDepth: 5, decisionTime: 3, randomSeed: 1)
		let engine = CaveRunEngine(graph: graph, config: config)

		if case .traveling(let travel) = engine.state.phase {
			XCTAssertEqual(travel.fromNodeID, 0)
			XCTAssertEqual(travel.toNodeID, 1)
			XCTAssertEqual(travel.remainingTime, 3, accuracy: 0.0001)
		} else {
			XCTFail("Expected traveling phase")
		}
	}

	func test_tick_reachesJunctionAndStartsDecisionTimer() {
		let graph = makeSimpleChoiceGraph()
		let config = CaveConfig(maxDepth: 5, decisionTime: 3, randomSeed: 2)
		var engine = CaveRunEngine(graph: graph, config: config)

		engine.tick(deltaTime: 3)

		if case .waitingForChoice(let decision) = engine.state.phase {
			XCTAssertEqual(decision.nodeID, 1)
			XCTAssertEqual(decision.remainingTime, 3, accuracy: 0.0001)
		} else {
			XCTFail("Expected waitingForChoice phase")
		}
	}

	func test_tick_whenDecisionExpires_endsWithMonsterAttack() {
		let graph = makeSimpleChoiceGraph()
		let config = CaveConfig(maxDepth: 5, decisionTime: 3, randomSeed: 3)
		var engine = CaveRunEngine(graph: graph, config: config)

		engine.tick(deltaTime: 3)
		engine.tick(deltaTime: 3)

		if case .ended(let outcome) = engine.state.phase {
			XCTAssertEqual(outcome, .monsterAttack)
		} else {
			XCTFail("Expected ended phase")
		}
	}

	func test_choose_validOption_travelsAndReachesExpectedEnding() {
		let graph = makeSimpleChoiceGraph()
		let config = CaveConfig(maxDepth: 5, decisionTime: 3, randomSeed: 4)
		var engine = CaveRunEngine(graph: graph, config: config)

		engine.tick(deltaTime: 3)
		XCTAssertTrue(engine.choose(optionIndex: 0))
		engine.tick(deltaTime: 3)

		if case .ended(let outcome) = engine.state.phase {
			XCTAssertEqual(outcome, .escapeTreasurePortal)
		} else {
			XCTFail("Expected ended phase")
		}
	}

	func test_choose_invalidOption_keepsWaitingForChoice() {
		let graph = makeSimpleChoiceGraph()
		let config = CaveConfig(maxDepth: 5, decisionTime: 3, randomSeed: 5)
		var engine = CaveRunEngine(graph: graph, config: config)

		engine.tick(deltaTime: 3)
		XCTAssertFalse(engine.choose(optionIndex: 7))

		if case .waitingForChoice = engine.state.phase {
			XCTAssertTrue(true)
		} else {
			XCTFail("Expected waitingForChoice phase")
		}
	}

	func test_tick_autoTraversesCorridorNodes() {
		let graph = makeCorridorGraph()
		let config = CaveConfig(maxDepth: 5, decisionTime: 2, randomSeed: 6)
		var engine = CaveRunEngine(graph: graph, config: config)

		engine.tick(deltaTime: 2)
		engine.tick(deltaTime: 2)

		if case .ended(let outcome) = engine.state.phase {
			XCTAssertEqual(outcome, .lostInDarkness)
		} else {
			XCTFail("Expected ended phase")
		}
	}

	private func makeSimpleChoiceGraph() -> CaveMapGraph {
		let root = CaveMapNode(id: 0, depth: 0, kind: .corridor, childNodeIDs: [1])
		let junction = CaveMapNode(id: 1, depth: 1, kind: .junction(optionCount: 2), childNodeIDs: [2, 3])
		let happy = CaveMapNode(id: 2, depth: 2, kind: .ending(.escapeTreasurePortal), childNodeIDs: [])
		let fatal = CaveMapNode(id: 3, depth: 2, kind: .ending(.fatalFall), childNodeIDs: [])

		return CaveMapGraph(rootNodeID: 0, nodes: [0: root, 1: junction, 2: happy, 3: fatal])
	}

	private func makeCorridorGraph() -> CaveMapGraph {
		let root = CaveMapNode(id: 0, depth: 0, kind: .corridor, childNodeIDs: [1])
		let middle = CaveMapNode(id: 1, depth: 1, kind: .corridor, childNodeIDs: [2])
		let ending = CaveMapNode(id: 2, depth: 2, kind: .ending(.lostInDarkness), childNodeIDs: [])

		return CaveMapGraph(rootNodeID: 0, nodes: [0: root, 1: middle, 2: ending])
	}
}
