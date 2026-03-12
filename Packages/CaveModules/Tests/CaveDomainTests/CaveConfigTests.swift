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
}
