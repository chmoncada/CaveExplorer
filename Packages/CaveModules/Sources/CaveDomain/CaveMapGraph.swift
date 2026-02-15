public struct CaveMapGraph: Equatable, Sendable {
	public let rootNodeID: Int
	public let nodes: [Int: CaveMapNode]

	public init(rootNodeID: Int, nodes: [Int: CaveMapNode]) {
		self.rootNodeID = rootNodeID
		self.nodes = nodes
	}

	public var endingNodes: [CaveMapNode] {
		nodes.values.filter { node in
			if case .ending = node.kind {
				return true
			}
			return false
		}
	}

	public var happyEndingNode: CaveMapNode? {
		endingNodes.first { node in
			if case .ending(let outcome) = node.kind {
				return outcome.isHappyEnding
			}
			return false
		}
	}
}
