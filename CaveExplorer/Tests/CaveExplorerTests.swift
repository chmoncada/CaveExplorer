import CaveDomain
import CaveMapEngine
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

	func test_startNewGame_exposesCurrentSeedForReproducibility() {
		let session = makeSession()

		session.startNewGame(seed: 123)

		XCTAssertEqual(session.currentSeed, 123)
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

	func test_applySettings_updatesSessionConfigForNextRun() {
		let session = makeSession()
		session.applySettings(
			CaveGameSettings(
				maxDepth: 9,
				decisionTime: 4.0,
				happyEndingStartPercent: 0.85
			)
		)

		XCTAssertEqual(session.maxDepth, 9)

		session.tick(deltaTime: 2.0)

		guard let travelState = session.runState else {
			XCTFail("Expected run state")
			return
		}

		if case .traveling = travelState.phase {
			// Expected: travel time uses updated settings.
		} else {
			XCTFail("Expected travel to still be active before 4 seconds")
		}

		session.tick(deltaTime: 2.1)

		guard let updatedState = session.runState else {
			XCTFail("Expected run state")
			return
		}

		if case .waitingForChoice(let decision) = updatedState.phase {
			XCTAssertEqual(decision.totalTime, 4.0, accuracy: 0.001)
		} else {
			XCTFail("Expected decision phase after completing travel")
		}
	}

	func test_runSummary_marksEscapeOutcomeAsSuccess() {
		let summary = CaveRunSummary(outcome: .escapeTreasurePortal, reachedDepth: 8, maxDepth: 10)

		XCTAssertTrue(summary.isSuccessful)
		XCTAssertEqual(summary.headline, "Escapaste de la cueva")
		XCTAssertEqual(summary.progressPercent, 80)
	}

	func test_runSummary_clampsProgressPercentWithinBounds() {
		let belowRange = CaveRunSummary(outcome: .fatalFall, reachedDepth: -2, maxDepth: 10)
		let aboveRange = CaveRunSummary(outcome: .monsterAttack, reachedDepth: 14, maxDepth: 10)

		XCTAssertEqual(belowRange.progressPercent, 0)
		XCTAssertEqual(aboveRange.progressPercent, 100)
		XCTAssertEqual(aboveRange.depthLine, "Profundidad alcanzada: 14 / 10 (100%)")
	}

	func test_runStats_recordingFailure_updatesBestDepthOnly() {
		let initial = CaveRunStats(bestDepth: 3, escapedRuns: 2)
		let summary = CaveRunSummary(outcome: .monsterAttack, reachedDepth: 7, maxDepth: 10)

		let updated = initial.recording(summary)

		XCTAssertEqual(updated.bestDepth, 7)
		XCTAssertEqual(updated.escapedRuns, 2)
	}

	func test_runStats_recordingSuccess_incrementsEscapesAndKeepsBestDepth() {
		let initial = CaveRunStats(bestDepth: 9, escapedRuns: 1)
		let summary = CaveRunSummary(outcome: .escapeTreasurePortal, reachedDepth: 6, maxDepth: 10)

		let updated = initial.recording(summary)

		XCTAssertEqual(updated.bestDepth, 9)
		XCTAssertEqual(updated.escapedRuns, 2)
	}

	func test_runSummary_exposesEstimatedDurationSeedAndDecisionLines() {
		let summary = CaveRunSummary(
			outcome: .escapeTreasurePortal,
			reachedDepth: 9,
			maxDepth: 10,
			estimatedDuration: 15.4,
			seed: 42,
			decisionsTaken: 5
		)

		XCTAssertTrue(summary.estimatedDurationLine.hasPrefix("Tiempo estimado: 15"))
		XCTAssertTrue(summary.estimatedDurationLine.hasSuffix("s"))
		XCTAssertEqual(summary.seedLine, "Seed: 42")
		XCTAssertEqual(summary.decisionsLine, "Decisiones tomadas: 5")
	}

	func test_runRecord_appending_keepsMostRecentEntriesWithinLimit() {
		let existing = [
			CaveRunRecord(summary: CaveRunSummary(outcome: .monsterAttack, reachedDepth: 2, maxDepth: 10)),
			CaveRunRecord(summary: CaveRunSummary(outcome: .fatalFall, reachedDepth: 3, maxDepth: 10)),
			CaveRunRecord(summary: CaveRunSummary(outcome: .cursedTreasure, reachedDepth: 4, maxDepth: 10))
		]

		let updated = CaveRunRecord.appending(
			summary: CaveRunSummary(outcome: .escapeTreasurePortal, reachedDepth: 8, maxDepth: 10),
			to: existing,
			limit: 3
		)

		XCTAssertEqual(updated.count, 3)
		XCTAssertEqual(updated.first?.outcomeTitle, "Tesoro encontrado")
	}

	func test_runRecord_appending_usesDefaultStoredHistoryLimit() {
		let records = Array(repeating: CaveRunRecord(summary: CaveRunSummary(outcome: .fatalFall, reachedDepth: 1, maxDepth: 10)), count: 20)
		let updated = CaveRunRecord.appending(
			summary: CaveRunSummary(outcome: .escapeTreasurePortal, reachedDepth: 10, maxDepth: 10),
			to: records
		)

		XCTAssertEqual(updated.count, CaveRunRecord.storedHistoryLimit)
		XCTAssertEqual(updated.first?.outcomeTitle, "Tesoro encontrado")
	}

	func test_runSummary_canBePersistedAsRecentRunFromSessionEnd() throws {
		let defaults = try makeIsolatedDefaults()
		let store = CavePreferencesStore.userDefaults(defaults)
		let session = makeSession()

		session.startNewGame(seed: 22)
		session.tick(deltaTime: 1.1)
		session.tick(deltaTime: 1.1)

		let summary = try XCTUnwrap(session.runSummary)
		let updatedHistory = CaveRunRecord.appending(summary: summary, to: store.load().recentRuns)
		store.saveRecentRuns(updatedHistory)

		let reloaded = store.load()
		XCTAssertEqual(reloaded.recentRuns.count, 1)
		XCTAssertEqual(reloaded.recentRuns.first?.seed, 22)
		XCTAssertEqual(reloaded.recentRuns.first?.decisionsTaken, 0)
	}

	func test_playingHappyPath_reachesVictoryWithSummaryMetrics() throws {
		let config = CaveConfig(maxDepth: 5, decisionTime: 1.0, happyEndingStartPercent: 0.8, randomSeed: 19)
		let session = CaveSession(config: config)
		let happyPath = try XCTUnwrap(makeHappyPath(for: config))

		playSession(session, using: happyPath, travelTime: 1.1)

		let summary = try XCTUnwrap(session.runSummary)
		guard case .ended(let outcome) = session.runState?.phase else {
			return XCTFail("Expected ended phase after following happy path")
		}

		XCTAssertEqual(outcome, .escapeTreasurePortal)
		XCTAssertTrue(summary.isSuccessful)
		XCTAssertEqual(summary.seed, 19)
		XCTAssertEqual(summary.decisionsTaken, happyPath.count)
		XCTAssertGreaterThan(summary.estimatedDuration, 0)
	}

	func test_timeoutEnding_persistsFailureRecentRunWithSeed() throws {
		let defaults = try makeIsolatedDefaults()
		let store = CavePreferencesStore.userDefaults(defaults)
		let session = makeSession()

		session.startNewGame(seed: 31)
		session.tick(deltaTime: 1.1)
		session.tick(deltaTime: 1.1)

		let summary = try XCTUnwrap(session.runSummary)
		store.saveRecentRuns(CaveRunRecord.appending(summary: summary, to: []))

		let record = try XCTUnwrap(store.load().recentRuns.first)
		XCTAssertFalse(record.isSuccessful)
		XCTAssertEqual(record.seed, 31)
		XCTAssertEqual(record.outcomeTitle, "El monstruo te alcanzo")
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

	private func makeHappyPath(for config: CaveConfig) -> [Int]? {
		let graph = CaveMapGenerator().generate(config: config)
		guard let happyNode = graph.happyEndingNode else { return nil }
		let path = pathFromRoot(to: happyNode.id, in: graph)
		return path.map { childIndex in
			childIndex
		}
	}

	private func pathFromRoot(to targetNodeID: Int, in graph: CaveMapGraph) -> [Int] {
		func search(nodeID: Int) -> [Int]? {
			guard let node = graph.nodes[nodeID] else { return nil }
			for (index, childID) in node.childNodeIDs.enumerated() {
				if childID == targetNodeID {
					if case .junction = node.kind {
						return [index]
					}
					return []
				}
				if let childPath = search(nodeID: childID) {
					if case .junction = node.kind {
						return [index] + childPath
					}
					return childPath
				}
			}
			return nil
		}

		return search(nodeID: graph.rootNodeID) ?? []
	}

	private func playSession(_ session: CaveSession, using choiceIndexes: [Int], travelTime: TimeInterval) {
		for choiceIndex in choiceIndexes {
			session.tick(deltaTime: travelTime)
			session.choose(optionIndex: choiceIndex)
		}
		session.tick(deltaTime: travelTime)
	}

	private func makeIsolatedDefaults() throws -> UserDefaults {
		let suiteName = "CaveExplorerTests.\(UUID().uuidString)"
		let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
		defaults.removePersistentDomain(forName: suiteName)
		return defaults
	}
}
