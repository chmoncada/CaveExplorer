import XCTest

@testable import CaveExplorer

final class CaveAudioSettingsTests: XCTestCase {
	func test_default_matchesExpectedValues() {
		let settings = CaveAudioSettings.default

		XCTAssertEqual(settings.effectsVolume, 0.9, accuracy: 0.0001)
		XCTAssertEqual(settings.musicVolume, 0.55, accuracy: 0.0001)
		XCTAssertFalse(settings.isMuted)
	}

	func test_normalized_clampsVolumeValues() {
		let settings = CaveAudioSettings(effectsVolume: 1.7, musicVolume: -0.4, isMuted: true)

		let normalized = settings.normalized

		XCTAssertEqual(normalized.effectsVolume, 1, accuracy: 0.0001)
		XCTAssertEqual(normalized.musicVolume, 0, accuracy: 0.0001)
		XCTAssertTrue(normalized.isMuted)
	}
}
