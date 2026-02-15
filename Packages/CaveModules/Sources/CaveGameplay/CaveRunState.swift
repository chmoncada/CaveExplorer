import CaveDomain
import Foundation

public struct TravelState: Equatable, Sendable {
	public let fromNodeID: Int
	public let toNodeID: Int
	public let totalTime: TimeInterval
	public let remainingTime: TimeInterval

	public init(fromNodeID: Int, toNodeID: Int, totalTime: TimeInterval, remainingTime: TimeInterval) {
		self.fromNodeID = fromNodeID
		self.toNodeID = toNodeID
		self.totalTime = totalTime
		self.remainingTime = remainingTime
	}

	public var progress: Double {
		guard totalTime > 0 else { return 1 }
		return min(1, max(0, 1 - (remainingTime / totalTime)))
	}
}

public struct DecisionState: Equatable, Sendable {
	public let nodeID: Int
	public let totalTime: TimeInterval
	public let remainingTime: TimeInterval

	public init(nodeID: Int, totalTime: TimeInterval, remainingTime: TimeInterval) {
		self.nodeID = nodeID
		self.totalTime = totalTime
		self.remainingTime = remainingTime
	}

	public var progress: Double {
		guard totalTime > 0 else { return 1 }
		return min(1, max(0, 1 - (remainingTime / totalTime)))
	}
}

public enum CaveRunPhase: Equatable, Sendable {
	case traveling(TravelState)
	case waitingForChoice(DecisionState)
	case ended(CaveOutcome)
}

public struct CaveRunState: Equatable, Sendable {
	public let currentNodeID: Int
	public let currentDepth: Int
	public let phase: CaveRunPhase

	public init(currentNodeID: Int, currentDepth: Int, phase: CaveRunPhase) {
		self.currentNodeID = currentNodeID
		self.currentDepth = currentDepth
		self.phase = phase
	}
}
