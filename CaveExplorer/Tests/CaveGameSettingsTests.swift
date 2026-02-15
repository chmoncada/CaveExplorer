import XCTest

@testable import CaveExplorer

final class CaveGameSettingsTests: XCTestCase {
	func test_normalized_clampsOutOfRangeValues() {
		let settings = CaveGameSettings(
			maxDepth: 99,
			decisionTime: 99,
			happyEndingStartPercent: 0.1
		)

		let normalized = settings.normalized

		XCTAssertEqual(normalized.maxDepth, CaveGameSettings.depthRange.upperBound)
		XCTAssertEqual(normalized.decisionTime, CaveGameSettings.decisionTimeRange.upperBound, accuracy: 0.001)
		XCTAssertEqual(
			normalized.happyEndingStartPercent,
			CaveGameSettings.happyEndingStartPercentRange.lowerBound,
			accuracy: 0.001
		)
	}

	func test_caveConfig_usesNormalizedSettings() {
		let settings = CaveGameSettings(
			maxDepth: 2,
			decisionTime: 2,
			happyEndingStartPercent: 1.0
		)

		let config = settings.caveConfig

		XCTAssertEqual(config.maxDepth, CaveGameSettings.depthRange.lowerBound)
		XCTAssertEqual(config.decisionTime, CaveGameSettings.decisionTimeRange.lowerBound, accuracy: 0.001)
		XCTAssertEqual(
			config.happyEndingStartPercent,
			CaveGameSettings.happyEndingStartPercentRange.upperBound,
			accuracy: 0.001
		)
	}

	func test_default_matchesExpectedValues() {
		let settings = CaveGameSettings.default

		XCTAssertEqual(settings.maxDepth, 5)
		XCTAssertEqual(settings.decisionTime, 5.0, accuracy: 0.001)
		XCTAssertEqual(settings.happyEndingStartPercent, 0.8, accuracy: 0.001)
	}
}
