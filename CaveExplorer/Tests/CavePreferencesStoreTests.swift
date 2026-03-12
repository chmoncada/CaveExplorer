import XCTest

@testable import CaveExplorer

final class CavePreferencesStoreTests: XCTestCase {
	func test_load_returnsDefaultsWhenNothingStored() throws {
		let defaults = try makeIsolatedDefaults()
		let store = CavePreferencesStore.userDefaults(defaults)

		let snapshot = store.load()

		XCTAssertEqual(snapshot.gameSettings, CaveGameSettings.default)
		XCTAssertEqual(snapshot.audioSettings, CaveAudioSettings.default)
	}

	func test_load_normalizesOutOfRangeStoredValues() throws {
		let defaults = try makeIsolatedDefaults()
		defaults.set(99, forKey: "cave.settings.maxDepth")
		defaults.set(1.7, forKey: "cave.settings.decisionTime")
		defaults.set(1.5, forKey: "cave.settings.happyEndingStartPercent")
		defaults.set(2.2, forKey: "cave.audio.effectsVolume")
		defaults.set(-0.6, forKey: "cave.audio.musicVolume")
		defaults.set(true, forKey: "cave.audio.isMuted")

		let store = CavePreferencesStore.userDefaults(defaults)
		let snapshot = store.load()

		XCTAssertEqual(snapshot.gameSettings.maxDepth, CaveGameSettings.depthRange.upperBound)
		XCTAssertEqual(snapshot.gameSettings.decisionTime, CaveGameSettings.decisionTimeRange.lowerBound, accuracy: 0.001)
		XCTAssertEqual(
			snapshot.gameSettings.happyEndingStartPercent,
			CaveGameSettings.happyEndingStartPercentRange.upperBound,
			accuracy: 0.001
		)
		XCTAssertEqual(snapshot.audioSettings.effectsVolume, 1, accuracy: 0.001)
		XCTAssertEqual(snapshot.audioSettings.musicVolume, 0, accuracy: 0.001)
		XCTAssertTrue(snapshot.audioSettings.isMuted)
	}

	func test_save_thenLoad_roundTripsNormalizedValues() throws {
		let defaults = try makeIsolatedDefaults()
		let store = CavePreferencesStore.userDefaults(defaults)

		store.saveGameSettings(
			CaveGameSettings(
				maxDepth: 2,
				decisionTime: 20,
				happyEndingStartPercent: 0.2
			)
		)
		store.saveAudioSettings(
			CaveAudioSettings(
				effectsVolume: -1,
				musicVolume: 5,
				isMuted: true
			)
		)

		let snapshot = store.load()

		XCTAssertEqual(snapshot.gameSettings.maxDepth, CaveGameSettings.depthRange.lowerBound)
		XCTAssertEqual(snapshot.gameSettings.decisionTime, CaveGameSettings.decisionTimeRange.upperBound, accuracy: 0.001)
		XCTAssertEqual(
			snapshot.gameSettings.happyEndingStartPercent,
			CaveGameSettings.happyEndingStartPercentRange.lowerBound,
			accuracy: 0.001
		)
		XCTAssertEqual(snapshot.audioSettings.effectsVolume, 0, accuracy: 0.001)
		XCTAssertEqual(snapshot.audioSettings.musicVolume, 1, accuracy: 0.001)
		XCTAssertTrue(snapshot.audioSettings.isMuted)
	}

	private func makeIsolatedDefaults() throws -> UserDefaults {
		let suiteName = "CavePreferencesStoreTests.\(UUID().uuidString)"
		let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
		defaults.removePersistentDomain(forName: suiteName)
		return defaults
	}
}
