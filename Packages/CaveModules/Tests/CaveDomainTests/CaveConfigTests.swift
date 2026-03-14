import CaveDomain
import XCTest

final class CaveConfigTests: XCTestCase {
	func test_minimumHappyDepth_usesLastTwentyPercentRule() {
		let config = CaveConfig(maxDepth: 5, happyEndingStartPercent: 0.8)
		XCTAssertEqual(config.minimumHappyDepth, 4)
	}

	func test_minimumHappyDepth_roundsUpWhenNeeded() {
		let config = CaveConfig(maxDepth: 6, happyEndingStartPercent: 0.8)
		XCTAssertEqual(config.minimumHappyDepth, 5)
	}

	func test_happyEndingDepthRange_startsAtMinimumDepth() {
		let config = CaveConfig(maxDepth: 10, happyEndingStartPercent: 0.7)
		XCTAssertEqual(config.happyEndingDepthRange, 7...10)
	}

	func test_happyEndingDepthRange_usesMaxDepthAsUpperBound() {
		let config = CaveConfig(maxDepth: 5, happyEndingStartPercent: 1.0)
		XCTAssertEqual(config.happyEndingDepthRange, 5...5)
	}

	func test_travelTime_getsFasterWithDepth() {
		let config = CaveConfig(maxDepth: 10, decisionTime: 6)
		XCTAssertGreaterThan(config.travelTime(forDepth: 1), config.travelTime(forDepth: 9))
	}

	func test_travelTime_isBoundedToAtLeastOneSecond() {
		let config = CaveConfig(maxDepth: 10, decisionTime: 1)
		XCTAssertEqual(config.travelTime(forDepth: 10), 1, accuracy: 0.001)
	}

	func test_earlyTerminationChance_startsAtZeroBeforeDepthTwo() {
		let config = CaveConfig(maxDepth: 8, happyEndingStartPercent: 0.75)
		XCTAssertEqual(config.earlyTerminationChance(atDepth: 1), 0, accuracy: 0.001)
	}

	func test_earlyTerminationChance_increasesTowardLateGame() {
		let config = CaveConfig(maxDepth: 10, happyEndingStartPercent: 0.8)
		XCTAssertLessThan(config.earlyTerminationChance(atDepth: 2), config.earlyTerminationChance(atDepth: 9))
	}
}
