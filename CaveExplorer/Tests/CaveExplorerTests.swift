import CaveDomain
import XCTest

@testable import CaveExplorer

@MainActor
final class CaveExplorerTests: XCTestCase {
	func test_startNewGame_createsInitialTravelState() {
		let session = makeSession()

		session.startNewGame(seed: 1)

		guard let runState = session.runState else {
			XCTFail("Expected run state after starting a game")
			return
		}

		if case .traveling = runState.phase {
			XCTAssertEqual(runState.currentDepth, 0)
		} else {
			XCTFail("Expected to start traveling from root")
		}
	}

	func test_tick_afterTravelTime_entersDecisionAndExposesChoices() {
		let session = makeSession()
		session.startNewGame(seed: 2)

		session.tick(deltaTime: 1.1)

		guard let runState = session.runState else {
			XCTFail("Expected run state")
			return
		}

		if case .waitingForChoice = runState.phase {
			XCTAssertFalse(session.choices.isEmpty)
			XCTAssertTrue((2...3).contains(session.choices.count))
		} else {
			XCTFail("Expected to arrive at a junction")
		}
	}

	func test_tick_whenDecisionTimeExpires_monsterAttackEndsRun() {
		let session = makeSession()
		session.startNewGame(seed: 3)

		session.tick(deltaTime: 1.1)
		session.tick(deltaTime: 1.1)

		guard let runState = session.runState else {
			XCTFail("Expected run state")
			return
		}

		if case .ended(let outcome) = runState.phase {
			XCTAssertEqual(outcome, .monsterAttack)
			XCTAssertTrue(session.isGameOver)
		} else {
			XCTFail("Expected the run to end by timeout")
		}
	}

	func test_choose_validOption_resumesTravelAndClearsChoiceButtons() {
		let session = makeSession()
		session.startNewGame(seed: 4)
		session.tick(deltaTime: 1.1)

		guard let option = session.choices.first?.optionIndex else {
			XCTFail("Expected at least one choice")
			return
		}

		session.choose(optionIndex: option)

		guard let runState = session.runState else {
			XCTFail("Expected run state")
			return
		}

		if case .traveling = runState.phase {
			XCTAssertTrue(session.choices.isEmpty)
		} else {
			XCTFail("Expected travel after selecting an option")
		}
	}

	private func makeSession() -> CaveSession {
		CaveSession(
			config: CaveConfig(
				maxDepth: 5,
				decisionTime: 1.0,
				happyEndingStartPercent: 0.8
			)
		)
	}
}
