import Foundation

public struct CaveConfig: Equatable, Sendable {
	public var maxDepth: Int
	public var decisionTime: TimeInterval
	public var minBranchOptions: Int
	public var maxBranchOptions: Int
	public var happyEndingStartPercent: Double
	public var randomSeed: UInt64?

	public init(
		maxDepth: Int = 5,
		decisionTime: TimeInterval = 5.0,
		minBranchOptions: Int = 2,
		maxBranchOptions: Int = 3,
		happyEndingStartPercent: Double = 0.8,
		randomSeed: UInt64? = nil
	) {
		precondition(maxDepth >= 1, "maxDepth must be >= 1")
		precondition(decisionTime > 0, "decisionTime must be > 0")
		precondition(minBranchOptions >= 2, "minBranchOptions must be >= 2")
		precondition(maxBranchOptions >= minBranchOptions, "maxBranchOptions must be >= minBranchOptions")
		precondition((0...1).contains(happyEndingStartPercent), "happyEndingStartPercent must be between 0 and 1")

		self.maxDepth = maxDepth
		self.decisionTime = decisionTime
		self.minBranchOptions = minBranchOptions
		self.maxBranchOptions = maxBranchOptions
		self.happyEndingStartPercent = happyEndingStartPercent
		self.randomSeed = randomSeed
	}

	public var minimumHappyDepth: Int {
		max(1, Int(ceil(Double(maxDepth) * happyEndingStartPercent)))
	}

	public var happyEndingDepthRange: ClosedRange<Int> {
		minimumHappyDepth...maxDepth
	}
}
