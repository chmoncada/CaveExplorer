import CaveDomain
import CaveGameplay
import Foundation
import XCTest

@testable import CaveExplorer

final class CaveSoundEventTrackerTests: XCTestCase {
	func test_cues_whenEnteringDecision_includesDecisionAppeared() {
		var tracker = CaveSoundEventTracker(urgencyThreshold: 0.3)

		_ = tracker.cues(for: travelingState())
		let cues = tracker.cues(for: waitingState(nodeID: 7, remaining: 4, total: 5))

		XCTAssertEqual(cues, [.decisionAppeared])
	}

	func test_cues_whenDecisionGetsUrgent_emitsUrgentOnlyOncePerNode() {
		var tracker = CaveSoundEventTracker(urgencyThreshold: 0.3)

		_ = tracker.cues(for: waitingState(nodeID: 11, remaining: 4, total: 5))

		let firstUrgent = tracker.cues(for: waitingState(nodeID: 11, remaining: 1.4, total: 5))
		let secondUrgent = tracker.cues(for: waitingState(nodeID: 11, remaining: 0.4, total: 5))

		XCTAssertEqual(firstUrgent, [.decisionUrgent])
		XCTAssertTrue(secondUrgent.isEmpty)
	}

	func test_cues_whenRunEnds_emitsEndingCueOnlyOnTransition() {
		var tracker = CaveSoundEventTracker()

		_ = tracker.cues(for: travelingState())
		let firstFailure = tracker.cues(for: endedState(.monsterAttack))
		let repeatedFailure = tracker.cues(for: endedState(.monsterAttack))
		let happyEnding = tracker.cues(for: endedState(.escapeTreasurePortal))

		XCTAssertEqual(firstFailure, [.failureEnding])
		XCTAssertTrue(repeatedFailure.isEmpty)
		XCTAssertEqual(happyEnding, [.happyEnding])
	}
}

@MainActor
final class CaveSoundControllerTests: XCTestCase {
	func test_startRun_playsRunStartedInitialCueAndStartsMusicLoop() {
		let spyPlayer = SpySoundPlayer()
		let spyMusicPlayer = SpyBackgroundMusicPlayer()
		let spyAmbientPlayer = SpyAmbientPlayer()
		let controller = CaveSoundController(
			player: spyPlayer,
			backgroundMusicPlayer: spyMusicPlayer,
			ambientPlayer: spyAmbientPlayer
		)

		controller.startRun(initialState: waitingState(nodeID: 1, remaining: 5, total: 5))

		XCTAssertEqual(spyPlayer.playedCues, [.runStarted, .decisionAppeared])
		XCTAssertEqual(spyMusicPlayer.startCalls, 2)
		XCTAssertEqual(spyAmbientPlayer.startCalls, 2)
		XCTAssertEqual(spyMusicPlayer.stopCalls, 0)
		XCTAssertEqual(spyAmbientPlayer.stopCalls, 0)
	}

	func test_choosePath_playsPathSelectedCue() {
		let spyPlayer = SpySoundPlayer()
		let controller = CaveSoundController(
			player: spyPlayer,
			backgroundMusicPlayer: SpyBackgroundMusicPlayer(),
			ambientPlayer: SpyAmbientPlayer()
		)

		controller.choosePath()

		XCTAssertEqual(spyPlayer.playedCues, [.pathSelected])
	}

	func test_handle_withEndedState_stopsMusicAndPlaysEndingCue() {
		let spyPlayer = SpySoundPlayer()
		let spyMusicPlayer = SpyBackgroundMusicPlayer()
		let spyAmbientPlayer = SpyAmbientPlayer()
		let controller = CaveSoundController(
			player: spyPlayer,
			backgroundMusicPlayer: spyMusicPlayer,
			ambientPlayer: spyAmbientPlayer
		)

		controller.handle(runState: endedState(.monsterAttack))

		XCTAssertEqual(spyPlayer.playedCues, [.failureEnding])
		XCTAssertEqual(spyMusicPlayer.startCalls, 0)
		XCTAssertEqual(spyAmbientPlayer.startCalls, 0)
		XCTAssertEqual(spyMusicPlayer.stopCalls, 1)
		XCTAssertEqual(spyAmbientPlayer.stopCalls, 1)
	}

	func test_handle_traveling_appliesTravelMixProfile() {
		let spyMusicPlayer = SpyBackgroundMusicPlayer()
		let spyAmbientPlayer = SpyAmbientPlayer()
		let controller = CaveSoundController(
			player: SpySoundPlayer(),
			backgroundMusicPlayer: spyMusicPlayer,
			ambientPlayer: spyAmbientPlayer
		)

		controller.handle(runState: travelingState())

		XCTAssertEqual(spyMusicPlayer.latestMixMultiplier, 1, accuracy: 0.0001)
		XCTAssertEqual(spyAmbientPlayer.latestMixMultiplier, 0.78, accuracy: 0.0001)
	}

	func test_handle_waitingForChoice_updatesMixWithRemainingTime() {
		let spyMusicPlayer = SpyBackgroundMusicPlayer()
		let spyAmbientPlayer = SpyAmbientPlayer()
		let controller = CaveSoundController(
			player: SpySoundPlayer(),
			backgroundMusicPlayer: spyMusicPlayer,
			ambientPlayer: spyAmbientPlayer
		)

		controller.handle(runState: waitingState(nodeID: 4, remaining: 5, total: 5))
		XCTAssertEqual(spyMusicPlayer.latestMixMultiplier, 0.92, accuracy: 0.0001)
		XCTAssertEqual(spyAmbientPlayer.latestMixMultiplier, 0.6, accuracy: 0.0001)

		controller.handle(runState: waitingState(nodeID: 4, remaining: 0, total: 5))
		XCTAssertEqual(spyMusicPlayer.latestMixMultiplier, 0.58, accuracy: 0.0001)
		XCTAssertEqual(spyAmbientPlayer.latestMixMultiplier, 0.36, accuracy: 0.0001)
	}

	func test_stopAll_resetsTrackerAndStopsMusic() {
		let spyPlayer = SpySoundPlayer()
		let spyMusicPlayer = SpyBackgroundMusicPlayer()
		let spyAmbientPlayer = SpyAmbientPlayer()
		let controller = CaveSoundController(
			player: spyPlayer,
			backgroundMusicPlayer: spyMusicPlayer,
			ambientPlayer: spyAmbientPlayer
		)

		controller.startRun(initialState: waitingState(nodeID: 3, remaining: 5, total: 5))
		controller.stopAll()
		controller.handle(runState: waitingState(nodeID: 3, remaining: 5, total: 5))

		XCTAssertEqual(spyMusicPlayer.stopCalls, 1)
		XCTAssertEqual(spyAmbientPlayer.stopCalls, 1)
		XCTAssertEqual(
			spyPlayer.playedCues,
			[.runStarted, .decisionAppeared, .decisionAppeared]
		)
	}

	func test_applySettings_updatesPlayers() {
		let spyPlayer = SpySoundPlayer()
		let spyMusicPlayer = SpyBackgroundMusicPlayer()
		let spyAmbientPlayer = SpyAmbientPlayer()
		let controller = CaveSoundController(
			player: spyPlayer,
			backgroundMusicPlayer: spyMusicPlayer,
			ambientPlayer: spyAmbientPlayer
		)

		controller.apply(settings: CaveAudioSettings(effectsVolume: 0.42, musicVolume: 0.18, isMuted: true))

		XCTAssertEqual(spyPlayer.latestEffectsVolume, 0.42, accuracy: 0.0001)
		XCTAssertTrue(spyPlayer.latestMutedState)
		XCTAssertEqual(spyMusicPlayer.latestMusicVolume, 0.18, accuracy: 0.0001)
		XCTAssertTrue(spyMusicPlayer.latestMutedState)
		XCTAssertEqual(spyAmbientPlayer.latestAmbientVolume, 0.099, accuracy: 0.0001)
		XCTAssertTrue(spyAmbientPlayer.latestMutedState)
	}

	func test_handle_rapidPhaseChanges_playsExpectedCuesWithoutDuplicateEnding() {
		let spyPlayer = SpySoundPlayer()
		let spyMusicPlayer = SpyBackgroundMusicPlayer()
		let spyAmbientPlayer = SpyAmbientPlayer()
		let controller = CaveSoundController(
			player: spyPlayer,
			backgroundMusicPlayer: spyMusicPlayer,
			ambientPlayer: spyAmbientPlayer
		)

		controller.startRun(initialState: waitingState(nodeID: 8, remaining: 5, total: 5))
		controller.handle(runState: travelingState())
		controller.handle(runState: waitingState(nodeID: 8, remaining: 1, total: 5))
		controller.handle(runState: endedState(.escapeTreasurePortal))
		controller.handle(runState: endedState(.escapeTreasurePortal))
		controller.handle(runState: nil)

		XCTAssertEqual(
			spyPlayer.playedCues,
			[.runStarted, .decisionAppeared, .decisionAppeared, .decisionUrgent, .happyEnding]
		)
		XCTAssertEqual(spyMusicPlayer.stopCalls, 3)
		XCTAssertEqual(spyAmbientPlayer.stopCalls, 3)
	}

	func test_stopAll_thenRestartRun_resetsTrackerForAnotherFastRun() {
		let spyPlayer = SpySoundPlayer()
		let controller = CaveSoundController(
			player: spyPlayer,
			backgroundMusicPlayer: SpyBackgroundMusicPlayer(),
			ambientPlayer: SpyAmbientPlayer()
		)

		controller.startRun(initialState: waitingState(nodeID: 2, remaining: 5, total: 5))
		controller.stopAll()
		controller.startRun(initialState: waitingState(nodeID: 2, remaining: 0.8, total: 5))

		XCTAssertEqual(
			spyPlayer.playedCues,
			[.runStarted, .decisionAppeared, .runStarted, .decisionAppeared, .decisionUrgent]
		)
	}

	private final class SpySoundPlayer: CaveSoundPlaying {
		private(set) var playedCues: [CaveSoundCue] = []
		private(set) var latestEffectsVolume: Float = 1
		private(set) var latestMutedState = false

		func play(cue: CaveSoundCue) {
			playedCues.append(cue)
		}

		func setEffectsVolume(_ volume: Float) {
			latestEffectsVolume = volume
		}

		func setMuted(_ isMuted: Bool) {
			latestMutedState = isMuted
		}
	}

	private final class SpyBackgroundMusicPlayer: CaveBackgroundMusicPlaying {
		private(set) var startCalls = 0
		private(set) var stopCalls = 0
		private(set) var latestMusicVolume: Float = 1
		private(set) var latestMixMultiplier: Float = 1
		private(set) var latestMutedState = false

		func startLoop() {
			startCalls += 1
		}

		func stop() {
			stopCalls += 1
		}

		func setMusicVolume(_ volume: Float) {
			latestMusicVolume = volume
		}

		func setMixMultiplier(_ multiplier: Float) {
			latestMixMultiplier = multiplier
		}

		func setMuted(_ isMuted: Bool) {
			latestMutedState = isMuted
		}
	}

	private final class SpyAmbientPlayer: CaveAmbientLayerPlaying {
		private(set) var startCalls = 0
		private(set) var stopCalls = 0
		private(set) var latestAmbientVolume: Float = 1
		private(set) var latestMixMultiplier: Float = 1
		private(set) var latestMutedState = false

		func startLoop() {
			startCalls += 1
		}

		func stop() {
			stopCalls += 1
		}

		func setAmbientVolume(_ volume: Float) {
			latestAmbientVolume = volume
		}

		func setMixMultiplier(_ multiplier: Float) {
			latestMixMultiplier = multiplier
		}

		func setMuted(_ isMuted: Bool) {
			latestMutedState = isMuted
		}
	}
}

private func travelingState() -> CaveRunState {
	CaveRunState(
		currentNodeID: 0,
		currentDepth: 0,
		phase: .traveling(
			TravelState(
				fromNodeID: 0,
				toNodeID: 1,
				totalTime: 5,
				remainingTime: 5
			)
		)
	)
}

private func waitingState(nodeID: Int, remaining: TimeInterval, total: TimeInterval) -> CaveRunState {
	CaveRunState(
		currentNodeID: nodeID,
		currentDepth: 1,
		phase: .waitingForChoice(
			DecisionState(
				nodeID: nodeID,
				totalTime: total,
				remainingTime: remaining
			)
		)
	)
}

private func endedState(_ outcome: CaveOutcome) -> CaveRunState {
	CaveRunState(currentNodeID: 99, currentDepth: 4, phase: .ended(outcome))
}
