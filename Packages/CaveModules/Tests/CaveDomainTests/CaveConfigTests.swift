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
}
