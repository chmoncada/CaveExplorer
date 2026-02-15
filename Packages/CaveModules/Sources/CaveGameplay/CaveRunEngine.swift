import CaveDomain
import Foundation

public struct CaveRunEngine: Sendable {
	private let graph: CaveMapGraph
	private let config: CaveConfig
	private var stateStorage: CaveRunState

	public init(graph: CaveMapGraph, config: CaveConfig) {
		self.graph = graph
		self.config = config

		let rootNode = graph.nodes[graph.rootNodeID] ?? CaveMapNode(
			id: graph.rootNodeID,
			depth: 0,
			kind: .ending(.lostInDarkness),
			childNodeIDs: []
		)

		if let nextNodeID = rootNode.childNodeIDs.first {
			let travel = TravelState(
				fromNodeID: rootNode.id,
				toNodeID: nextNodeID,
				totalTime: config.decisionTime,
				remainingTime: config.decisionTime
			)
			self.stateStorage = CaveRunState(currentNodeID: rootNode.id, currentDepth: rootNode.depth, phase: .traveling(travel))
		} else {
			self.stateStorage = CaveRunState(currentNodeID: rootNode.id, currentDepth: rootNode.depth, phase: .ended(.lostInDarkness))
		}
	}

	public var state: CaveRunState {
		stateStorage
	}

	public mutating func tick(deltaTime: TimeInterval) {
		guard deltaTime > 0 else { return }

		switch stateStorage.phase {
		case .ended:
			return
		case .traveling(let travel):
			handleTravelTick(travel: travel, deltaTime: deltaTime)
		case .waitingForChoice(let decision):
			handleDecisionTick(decision: decision, deltaTime: deltaTime)
		}
	}

	@discardableResult
	public mutating func choose(optionIndex: Int) -> Bool {
		guard case .waitingForChoice(let decisionState) = stateStorage.phase else { return false }
		guard let node = graph.nodes[decisionState.nodeID] else { return false }
		guard node.childNodeIDs.indices.contains(optionIndex) else { return false }

		let targetNodeID = node.childNodeIDs[optionIndex]
		beginTravel(fromNodeID: node.id, toNodeID: targetNodeID)
		return true
	}

	private mutating func handleTravelTick(travel: TravelState, deltaTime: TimeInterval) {
		let remaining = max(0, travel.remainingTime - deltaTime)
		if remaining > 0 {
			stateStorage = CaveRunState(
				currentNodeID: stateStorage.currentNodeID,
				currentDepth: stateStorage.currentDepth,
				phase: .traveling(
					TravelState(
						fromNodeID: travel.fromNodeID,
						toNodeID: travel.toNodeID,
						totalTime: travel.totalTime,
						remainingTime: remaining
					)
				)
			)
			return
		}

		arrive(nodeID: travel.toNodeID)
	}

	private mutating func handleDecisionTick(decision: DecisionState, deltaTime: TimeInterval) {
		let remaining = max(0, decision.remainingTime - deltaTime)
		if remaining > 0 {
			stateStorage = CaveRunState(
				currentNodeID: stateStorage.currentNodeID,
				currentDepth: stateStorage.currentDepth,
				phase: .waitingForChoice(
					DecisionState(
						nodeID: decision.nodeID,
						totalTime: decision.totalTime,
						remainingTime: remaining
					)
				)
			)
			return
		}

		stateStorage = CaveRunState(
			currentNodeID: decision.nodeID,
			currentDepth: graph.nodes[decision.nodeID]?.depth ?? 0,
			phase: .ended(.monsterAttack)
		)
	}

	private mutating func arrive(nodeID: Int) {
		guard let node = graph.nodes[nodeID] else {
			stateStorage = CaveRunState(currentNodeID: nodeID, currentDepth: 0, phase: .ended(.lostInDarkness))
			return
		}

		switch node.kind {
		case .ending(let outcome):
			stateStorage = CaveRunState(currentNodeID: node.id, currentDepth: node.depth, phase: .ended(outcome))
		case .corridor:
			guard let nextNodeID = node.childNodeIDs.first else {
				stateStorage = CaveRunState(currentNodeID: node.id, currentDepth: node.depth, phase: .ended(.lostInDarkness))
				return
			}
			beginTravel(fromNodeID: node.id, toNodeID: nextNodeID)
		case .junction:
			stateStorage = CaveRunState(
				currentNodeID: node.id,
				currentDepth: node.depth,
				phase: .waitingForChoice(
					DecisionState(
						nodeID: node.id,
						totalTime: config.decisionTime,
						remainingTime: config.decisionTime
					)
				)
			)
		}
	}

	private mutating func beginTravel(fromNodeID: Int, toNodeID: Int) {
		let fromDepth = graph.nodes[fromNodeID]?.depth ?? 0
		stateStorage = CaveRunState(
			currentNodeID: fromNodeID,
			currentDepth: fromDepth,
			phase: .traveling(
				TravelState(
					fromNodeID: fromNodeID,
					toNodeID: toNodeID,
					totalTime: config.decisionTime,
					remainingTime: config.decisionTime
				)
			)
		)
	}
}
