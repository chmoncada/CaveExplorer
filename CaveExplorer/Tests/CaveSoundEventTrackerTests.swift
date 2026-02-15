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
	func test_startRun_playsRunStartedAndInitialStateCues() {
		let spyPlayer = SpySoundPlayer()
		let controller = CaveSoundController(player: spyPlayer)

		controller.startRun(initialState: waitingState(nodeID: 1, remaining: 5, total: 5))

		XCTAssertEqual(spyPlayer.playedCues, [.runStarted, .decisionAppeared])
	}

	func test_choosePath_playsPathSelectedCue() {
		let spyPlayer = SpySoundPlayer()
		let controller = CaveSoundController(player: spyPlayer)

		controller.choosePath()

		XCTAssertEqual(spyPlayer.playedCues, [.pathSelected])
	}

	private final class SpySoundPlayer: CaveSoundPlaying {
		private(set) var playedCues: [CaveSoundCue] = []

		func play(cue: CaveSoundCue) {
			playedCues.append(cue)
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
