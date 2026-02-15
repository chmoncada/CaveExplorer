import AppKit
import CaveDomain
import CaveGameplay
import Foundation

enum CaveSoundCue: Hashable {
	case runStarted
	case decisionAppeared
	case decisionUrgent
	case pathSelected
	case failureEnding
	case happyEnding

	var systemSoundName: NSSound.Name {
		switch self {
		case .runStarted:
			return NSSound.Name("Pop")
		case .decisionAppeared:
			return NSSound.Name("Ping")
		case .decisionUrgent:
			return NSSound.Name("Basso")
		case .pathSelected:
			return NSSound.Name("Tink")
		case .failureEnding:
			return NSSound.Name("Funk")
		case .happyEnding:
			return NSSound.Name("Hero")
		}
	}
}

@MainActor
protocol CaveSoundPlaying: AnyObject {
	func play(cue: CaveSoundCue)
}

@MainActor
final class CaveSystemSoundPlayer: CaveSoundPlaying {
	private var sounds: [CaveSoundCue: NSSound] = [:]

	func play(cue: CaveSoundCue) {
		guard let sound = sound(for: cue) else { return }
		sound.stop()
		sound.play()
	}

	private func sound(for cue: CaveSoundCue) -> NSSound? {
		if let cached = sounds[cue] {
			return cached
		}

		guard let loaded = NSSound(named: cue.systemSoundName) else {
			return nil
		}
		sounds[cue] = loaded
		return loaded
	}
}

struct CaveSoundEventTracker {
	private let urgencyThreshold: Double
	private var previousPhase: CaveRunPhase?
	private var warnedNodeIDs: Set<Int>

	init(urgencyThreshold: Double = 0.3) {
		self.urgencyThreshold = urgencyThreshold
		self.previousPhase = nil
		self.warnedNodeIDs = []
	}

	mutating func reset() {
		previousPhase = nil
		warnedNodeIDs.removeAll()
	}

	mutating func cues(for runState: CaveRunState?) -> [CaveSoundCue] {
		guard let runState else {
			reset()
			return []
		}

		var cues: [CaveSoundCue] = []
		defer {
			previousPhase = runState.phase
		}

		switch runState.phase {
		case .traveling:
			return cues
		case .waitingForChoice(let decision):
			if didEnterNewDecision(decision) {
				cues.append(.decisionAppeared)
			}

			if shouldWarnDecisionTimeout(decision) {
				cues.append(.decisionUrgent)
			}
		case .ended(let outcome):
			if shouldPlayEndingCue(outcome) {
				let cue: CaveSoundCue = outcome == .escapeTreasurePortal ? .happyEnding : .failureEnding
				cues.append(cue)
			}
		}

		return cues
	}

	private func didEnterNewDecision(_ decision: DecisionState) -> Bool {
		guard case .waitingForChoice(let previousDecision) = previousPhase else {
			return true
		}
		return previousDecision.nodeID != decision.nodeID
	}

	private mutating func shouldWarnDecisionTimeout(_ decision: DecisionState) -> Bool {
		guard decision.totalTime > 0 else { return false }
		let remainingRatio = decision.remainingTime / decision.totalTime
		guard remainingRatio <= urgencyThreshold else { return false }
		guard !warnedNodeIDs.contains(decision.nodeID) else { return false }
		warnedNodeIDs.insert(decision.nodeID)
		return true
	}

	private func shouldPlayEndingCue(_ outcome: CaveOutcome) -> Bool {
		guard case .ended(let previousOutcome) = previousPhase else { return true }
		return previousOutcome != outcome
	}
}

@MainActor
final class CaveSoundController {
	private let player: any CaveSoundPlaying
	private var tracker: CaveSoundEventTracker

	convenience init() {
		self.init(player: CaveSystemSoundPlayer())
	}

	init(
		player: any CaveSoundPlaying,
		tracker: CaveSoundEventTracker = CaveSoundEventTracker()
	) {
		self.player = player
		self.tracker = tracker
	}

	func startRun(initialState: CaveRunState?) {
		tracker.reset()
		player.play(cue: .runStarted)
		handle(runState: initialState)
	}

	func choosePath() {
		player.play(cue: .pathSelected)
	}

	func handle(runState: CaveRunState?) {
		let cues = tracker.cues(for: runState)
		for cue in cues {
			player.play(cue: cue)
		}
	}
}
