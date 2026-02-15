public struct CaveMapNode: Equatable, Sendable {
	public let id: Int
	public let depth: Int
	public let kind: CaveNodeKind
	public let childNodeIDs: [Int]

	public init(id: Int, depth: Int, kind: CaveNodeKind, childNodeIDs: [Int]) {
		self.id = id
		self.depth = depth
		self.kind = kind
		self.childNodeIDs = childNodeIDs
	}
}
