import AVFAudio
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

	var fileName: String {
		switch self {
		case .runStarted:
			return "run_started"
		case .decisionAppeared:
			return "decision_appeared"
		case .decisionUrgent:
			return "decision_urgent"
		case .pathSelected:
			return "path_selected"
		case .failureEnding:
			return "failure_ending"
		case .happyEnding:
			return "happy_ending"
		}
	}

	var volume: Float {
		switch self {
		case .runStarted:
			return 0.75
		case .decisionAppeared:
			return 0.78
		case .decisionUrgent:
			return 0.92
		case .pathSelected:
			return 0.72
		case .failureEnding:
			return 0.85
		case .happyEnding:
			return 0.9
		}
	}
}

@MainActor
protocol CaveSoundPlaying: AnyObject {
	func play(cue: CaveSoundCue)
	func setEffectsVolume(_ volume: Float)
	func setMuted(_ isMuted: Bool)
}

@MainActor
protocol CaveBackgroundMusicPlaying: AnyObject {
	func startLoop()
	func stop()
	func setMusicVolume(_ volume: Float)
	func setMixMultiplier(_ multiplier: Float)
	func setMuted(_ isMuted: Bool)
}

@MainActor
protocol CaveAmbientLayerPlaying: AnyObject {
	func startLoop()
	func stop()
	func setAmbientVolume(_ volume: Float)
	func setMixMultiplier(_ multiplier: Float)
	func setMuted(_ isMuted: Bool)
}

@MainActor
final class CaveBundleSoundPlayer: CaveSoundPlaying {
	private let bundle: Bundle
	private var players: [CaveSoundCue: AVAudioPlayer] = [:]
	private var effectsVolume = Float(CaveAudioSettings.default.effectsVolume)
	private var isMuted = CaveAudioSettings.default.isMuted

	init(bundle: Bundle = .main) {
		self.bundle = bundle
	}

	func play(cue: CaveSoundCue) {
		guard let player = player(for: cue) else { return }
		player.currentTime = 0
		player.play()
	}

	func setEffectsVolume(_ volume: Float) {
		effectsVolume = min(1, max(0, volume))
		updateAllPlayerVolumes()
	}

	func setMuted(_ isMuted: Bool) {
		self.isMuted = isMuted
		updateAllPlayerVolumes()
	}

	private func player(for cue: CaveSoundCue) -> AVAudioPlayer? {
		if let cached = players[cue] {
			return cached
		}

		guard let url = resourceURL(fileName: cue.fileName) else {
			return nil
		}

		do {
			let player = try AVAudioPlayer(contentsOf: url)
			player.volume = effectiveVolume(for: cue)
			player.prepareToPlay()
			players[cue] = player
			return player
		} catch {
			return nil
		}
	}

	private func effectiveVolume(for cue: CaveSoundCue) -> Float {
		guard !isMuted else { return 0 }
		return cue.volume * effectsVolume
	}

	private func updateAllPlayerVolumes() {
		for (cue, player) in players {
			player.volume = effectiveVolume(for: cue)
		}
	}

	private func resourceURL(fileName: String) -> URL? {
		bundle.url(forResource: fileName, withExtension: "wav", subdirectory: "Audio")
			?? bundle.url(forResource: fileName, withExtension: "wav")
	}
}

@MainActor
final class CaveBackgroundMusicPlayer: CaveBackgroundMusicPlaying {
	private let bundle: Bundle
	private var player: AVAudioPlayer?
	private var musicVolume = Float(CaveAudioSettings.default.musicVolume)
	private var mixMultiplier: Float = 1
	private var isMuted = CaveAudioSettings.default.isMuted

	init(bundle: Bundle = .main) {
		self.bundle = bundle
	}

	func startLoop() {
		guard let player = loadPlayerIfNeeded() else { return }
		guard !player.isPlaying else { return }
		player.currentTime = 0
		player.play()
	}

	func stop() {
		player?.stop()
	}

	func setMusicVolume(_ volume: Float) {
		musicVolume = min(1, max(0, volume))
		updatePlayerVolume()
	}

	func setMixMultiplier(_ multiplier: Float) {
		mixMultiplier = min(1, max(0, multiplier))
		updatePlayerVolume()
	}

	func setMuted(_ isMuted: Bool) {
		self.isMuted = isMuted
		updatePlayerVolume()
	}

	private func loadPlayerIfNeeded() -> AVAudioPlayer? {
		if let player {
			return player
		}

		guard let url = resourceURL(fileName: "bg_chase_loop") else {
			return nil
		}

		do {
			let loadedPlayer = try AVAudioPlayer(contentsOf: url)
			loadedPlayer.numberOfLoops = -1
			loadedPlayer.volume = effectiveMusicVolume
			loadedPlayer.prepareToPlay()
			player = loadedPlayer
			return loadedPlayer
		} catch {
			return nil
		}
	}

	private var effectiveMusicVolume: Float {
		isMuted ? 0 : musicVolume * mixMultiplier
	}

	private func updatePlayerVolume() {
		player?.setVolume(effectiveMusicVolume, fadeDuration: 0.24)
	}

	private func resourceURL(fileName: String) -> URL? {
		bundle.url(forResource: fileName, withExtension: "wav", subdirectory: "Audio")
			?? bundle.url(forResource: fileName, withExtension: "wav")
	}
}

@MainActor
final class CaveAmbientLayerPlayer: CaveAmbientLayerPlaying {
	private let bundle: Bundle
	private var player: AVAudioPlayer?
	private var ambientVolume = Float(CaveAudioSettings.default.musicVolume) * 0.55
	private var mixMultiplier: Float = 1
	private var isMuted = CaveAudioSettings.default.isMuted

	init(bundle: Bundle = .main) {
		self.bundle = bundle
	}

	func startLoop() {
		guard let player = loadPlayerIfNeeded() else { return }
		guard !player.isPlaying else { return }
		player.currentTime = 0
		player.play()
	}

	func stop() {
		player?.stop()
	}

	func setAmbientVolume(_ volume: Float) {
		ambientVolume = min(1, max(0, volume))
		updatePlayerVolume()
	}

	func setMixMultiplier(_ multiplier: Float) {
		mixMultiplier = min(1, max(0, multiplier))
		updatePlayerVolume()
	}

	func setMuted(_ isMuted: Bool) {
		self.isMuted = isMuted
		updatePlayerVolume()
	}

	private func loadPlayerIfNeeded() -> AVAudioPlayer? {
		if let player {
			return player
		}

		guard let url = resourceURL(fileName: "bg_ambient_loop") else {
			return nil
		}

		do {
			let loadedPlayer = try AVAudioPlayer(contentsOf: url)
			loadedPlayer.numberOfLoops = -1
			loadedPlayer.volume = effectiveAmbientVolume
			loadedPlayer.prepareToPlay()
			player = loadedPlayer
			return loadedPlayer
		} catch {
			return nil
		}
	}

	private var effectiveAmbientVolume: Float {
		isMuted ? 0 : ambientVolume * mixMultiplier
	}

	private func updatePlayerVolume() {
		player?.setVolume(effectiveAmbientVolume, fadeDuration: 0.3)
	}

	private func resourceURL(fileName: String) -> URL? {
		bundle.url(forResource: fileName, withExtension: "wav", subdirectory: "Audio")
			?? bundle.url(forResource: fileName, withExtension: "wav")
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
	private enum MixProfile {
		static let ambientBaseGain: Float = 0.55
	}

	private let player: any CaveSoundPlaying
	private let backgroundMusicPlayer: any CaveBackgroundMusicPlaying
	private let ambientPlayer: any CaveAmbientLayerPlaying
	private var tracker: CaveSoundEventTracker

	convenience init() {
		self.init(
			player: CaveBundleSoundPlayer(),
			backgroundMusicPlayer: CaveBackgroundMusicPlayer(),
			ambientPlayer: CaveAmbientLayerPlayer()
		)
	}

	init(
		player: any CaveSoundPlaying,
		backgroundMusicPlayer: any CaveBackgroundMusicPlaying,
		ambientPlayer: any CaveAmbientLayerPlaying,
		tracker: CaveSoundEventTracker = CaveSoundEventTracker()
	) {
		self.player = player
		self.backgroundMusicPlayer = backgroundMusicPlayer
		self.ambientPlayer = ambientPlayer
		self.tracker = tracker
	}

	func apply(settings: CaveAudioSettings) {
		let normalized = settings.normalized
		player.setEffectsVolume(Float(normalized.effectsVolume))
		player.setMuted(normalized.isMuted)

		backgroundMusicPlayer.setMusicVolume(Float(normalized.musicVolume))
		backgroundMusicPlayer.setMuted(normalized.isMuted)

		ambientPlayer.setAmbientVolume(Float(normalized.musicVolume) * MixProfile.ambientBaseGain)
		ambientPlayer.setMuted(normalized.isMuted)
	}

	func startRun(initialState: CaveRunState?) {
		tracker.reset()
		backgroundMusicPlayer.startLoop()
		ambientPlayer.startLoop()
		player.play(cue: .runStarted)
		handle(runState: initialState)
	}

	func choosePath() {
		player.play(cue: .pathSelected)
	}

	func handle(runState: CaveRunState?) {
		guard let runState else {
			stopAll()
			return
		}

		switch runState.phase {
		case .traveling, .waitingForChoice:
			backgroundMusicPlayer.startLoop()
			ambientPlayer.startLoop()
			applyMix(for: runState.phase)
		case .ended:
			backgroundMusicPlayer.stop()
			ambientPlayer.stop()
		}

		let cues = tracker.cues(for: runState)
		for cue in cues {
			player.play(cue: cue)
		}
	}

	func stopAll() {
		tracker.reset()
		backgroundMusicPlayer.stop()
		ambientPlayer.stop()
	}

	private func applyMix(for phase: CaveRunPhase) {
		switch phase {
		case .traveling:
			backgroundMusicPlayer.setMixMultiplier(1)
			ambientPlayer.setMixMultiplier(0.78)
		case .waitingForChoice(let decision):
			let remainingRatio = normalizedRatio(
				remaining: decision.remainingTime,
				total: decision.totalTime
			)
			let musicMix = Float(0.58 + 0.34 * remainingRatio)
			let ambientMix = Float(0.36 + 0.24 * remainingRatio)
			backgroundMusicPlayer.setMixMultiplier(musicMix)
			ambientPlayer.setMixMultiplier(ambientMix)
		case .ended:
			backgroundMusicPlayer.setMixMultiplier(0)
			ambientPlayer.setMixMultiplier(0)
		}
	}

	private func normalizedRatio(remaining: TimeInterval, total: TimeInterval) -> Double {
		guard total > 0 else { return 0 }
		let raw = remaining / total
		return min(1, max(0, raw))
	}
}
