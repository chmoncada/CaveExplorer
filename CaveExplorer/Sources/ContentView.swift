import CaveDomain
import SwiftUI

struct ContentView: View {
	@State private var settings: CaveGameSettings
	@State private var audioSettings: CaveAudioSettings
	@State private var selectedPreset: CaveGamePreset?
	@State private var session: CaveSession
	@State private var runStats: CaveRunStats
	@State private var recentRuns: [CaveRunRecord]
	@State private var lastRecordedRunSummary: CaveRunSummary?
	@State private var showOnboarding: Bool
	@State private var torchPulse = 0.0
	@State private var gameFlow: GameFlow = .home
	@State private var presentedSheet: PresentedSheet?
	@State private var soundController = CaveSoundController()
	private let preferencesStore: CavePreferencesStore

	private let tunnelBuilder = CaveTunnelFrameBuilder(segmentCount: 11)
	private let atmosphereBuilder = CaveAtmosphereFrameBuilder(fogBandCount: 4, dustCount: 36, batCount: 3)

	init(preferencesStore: CavePreferencesStore = .live) {
		self.preferencesStore = preferencesStore
		let snapshot = preferencesStore.load()
		_settings = State(initialValue: snapshot.gameSettings)
		_audioSettings = State(initialValue: snapshot.audioSettings)
		_selectedPreset = State(initialValue: CaveGamePreset.matching(settings: snapshot.gameSettings))
		_session = State(initialValue: CaveSession(config: snapshot.gameSettings.caveConfig))
		_runStats = State(initialValue: snapshot.runStats)
		_recentRuns = State(initialValue: snapshot.recentRuns)
		_lastRecordedRunSummary = State(initialValue: nil)
		_showOnboarding = State(initialValue: !snapshot.hasSeenOnboarding)
	}

	public var body: some View {
		ZStack {
			CaveRunSceneView(
				tunnelBuilder: tunnelBuilder,
				atmosphereBuilder: atmosphereBuilder,
				travelProgress: sceneTravelProgress,
				depthProgress: sceneDepthProgress,
				decisionRemainingRatio: sceneDecisionRemainingRatio,
				decisionChoiceCount: sceneChoiceCount,
				isGameOver: sceneIsGameOver,
				torchPulse: torchPulse
			)

			if gameFlow == .playing {
				GameplayOverlayView(
					session: session,
					onChoose: { optionIndex in
						session.choose(optionIndex: optionIndex)
						soundController.choosePath()
					},
					onNewMap: {
						startRun()
					},
					onReturnHome: {
						returnHome()
					}
				)
				.padding(22)
			} else {
				StartMenuOverlayView(
					settings: settings,
					runStats: runStats,
					recentRuns: recentRuns,
					showOnboarding: showOnboarding,
					selectedPreset: selectedPreset,
					onSelectPreset: { preset in
						selectedPreset = preset
						settings = preset.settings
					},
					onDismissOnboarding: {
						showOnboarding = false
						preferencesStore.saveHasSeenOnboarding(true)
					},
					onStart: {
						startRun()
					},
					onOpenSettings: {
						presentedSheet = .settings
					}
				)
			}
		}
		.frame(minWidth: 960, minHeight: 640)
		.sheet(item: $presentedSheet) { sheet in
			switch sheet {
			case .settings:
				CaveSettingsSheetView(
					settings: $settings,
					audioSettings: $audioSettings,
					onSettingsChanged: { updatedSettings in
						selectedPreset = CaveGamePreset.matching(settings: updatedSettings)
					},
					onClose: {
						presentedSheet = nil
					}
				)
			}
		}
		.task {
			await runGameLoop()
		}
		.task {
			await runTorchAnimationLoop()
		}
		.task {
			soundController.apply(settings: audioSettings)
		}
		.onChange(of: audioSettings) { _, updatedAudioSettings in
			preferencesStore.saveAudioSettings(updatedAudioSettings)
			soundController.apply(settings: updatedAudioSettings)
		}
		.onChange(of: settings) { _, updatedSettings in
			preferencesStore.saveGameSettings(updatedSettings)
			selectedPreset = CaveGamePreset.matching(settings: updatedSettings)
		}
	}

	private var sceneTravelProgress: Double {
		guard gameFlow == .playing else { return 0.28 }
		return session.travelProgress ?? 0
	}

	private var sceneDepthProgress: Double {
		guard gameFlow == .playing else { return 0.0 }
		return session.depthProgress
	}

	private var sceneDecisionRemainingRatio: Double? {
		guard gameFlow == .playing else { return nil }
		return session.decisionRemainingRatio
	}

	private var sceneChoiceCount: Int {
		guard gameFlow == .playing else { return 0 }
		return session.choices.count
	}

	private var sceneIsGameOver: Bool {
		gameFlow == .playing && session.isGameOver
	}

	private func startRun() {
		session = CaveSession(config: settings.caveConfig)
		lastRecordedRunSummary = nil
		gameFlow = .playing
		soundController.apply(settings: audioSettings)
		soundController.startRun(initialState: session.runState)
	}

	private func returnHome() {
		gameFlow = .home
		soundController.stopAll()
	}

	private func runGameLoop() async {
		let frameDuration = Duration.milliseconds(50)
		let fixedDelta = 0.05

		while !Task.isCancelled {
			if gameFlow == .playing {
				session.tick(deltaTime: fixedDelta)
				soundController.handle(runState: session.runState)

				if let summary = session.runSummary, summary != lastRecordedRunSummary {
					runStats = runStats.recording(summary)
					recentRuns = CaveRunRecord.appending(summary: summary, to: recentRuns)
					preferencesStore.saveRunStats(runStats)
					preferencesStore.saveRecentRuns(recentRuns)
					lastRecordedRunSummary = summary
				}
			}
			try? await Task.sleep(for: frameDuration)
		}
	}

	private func runTorchAnimationLoop() async {
		while !Task.isCancelled {
			withAnimation(.easeInOut(duration: 0.35)) {
				torchPulse = Double.random(in: 0...1)
			}
			try? await Task.sleep(for: .milliseconds(350))
		}
	}
}

private enum GameFlow {
	case home
	case playing
}

private enum PresentedSheet: String, Identifiable {
	case settings

	var id: String {
		rawValue
	}
}
