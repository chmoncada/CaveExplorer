import Foundation

struct CavePreferencesSnapshot: Equatable {
	var gameSettings: CaveGameSettings
	var audioSettings: CaveAudioSettings
	var runStats: CaveRunStats
	var hasSeenOnboarding: Bool
}

struct CavePreferencesStore {
	private enum Keys {
		static let maxDepth = "cave.settings.maxDepth"
		static let decisionTime = "cave.settings.decisionTime"
		static let happyEndingStartPercent = "cave.settings.happyEndingStartPercent"
		static let effectsVolume = "cave.audio.effectsVolume"
		static let musicVolume = "cave.audio.musicVolume"
		static let isMuted = "cave.audio.isMuted"
		static let bestDepth = "cave.stats.bestDepth"
		static let escapedRuns = "cave.stats.escapedRuns"
		static let hasSeenOnboarding = "cave.ui.hasSeenOnboarding"
	}

	var load: () -> CavePreferencesSnapshot
	var saveGameSettings: (CaveGameSettings) -> Void
	var saveAudioSettings: (CaveAudioSettings) -> Void
	var saveRunStats: (CaveRunStats) -> Void
	var saveHasSeenOnboarding: (Bool) -> Void

	static let live = userDefaults()

	static func userDefaults(_ defaults: UserDefaults = .standard) -> CavePreferencesStore {
		CavePreferencesStore(
			load: {
				let defaultGameSettings = CaveGameSettings.default
				let defaultAudioSettings = CaveAudioSettings.default
				let defaultRunStats = CaveRunStats.empty

				let storedGameSettings = CaveGameSettings(
					maxDepth: defaults.object(forKey: Keys.maxDepth) as? Int ?? defaultGameSettings.maxDepth,
					decisionTime: defaults.object(forKey: Keys.decisionTime) as? Double ?? defaultGameSettings.decisionTime,
					happyEndingStartPercent:
						defaults.object(forKey: Keys.happyEndingStartPercent) as? Double
							?? defaultGameSettings.happyEndingStartPercent
				).normalized

				let storedAudioSettings = CaveAudioSettings(
					effectsVolume:
						defaults.object(forKey: Keys.effectsVolume) as? Double
							?? defaultAudioSettings.effectsVolume,
					musicVolume:
						defaults.object(forKey: Keys.musicVolume) as? Double
							?? defaultAudioSettings.musicVolume,
					isMuted: defaults.object(forKey: Keys.isMuted) as? Bool ?? defaultAudioSettings.isMuted
				).normalized

				let storedRunStats = CaveRunStats(
					bestDepth: defaults.object(forKey: Keys.bestDepth) as? Int ?? defaultRunStats.bestDepth,
					escapedRuns: defaults.object(forKey: Keys.escapedRuns) as? Int ?? defaultRunStats.escapedRuns
				).normalized

				let hasSeenOnboarding = defaults.object(forKey: Keys.hasSeenOnboarding) as? Bool ?? false

				return CavePreferencesSnapshot(
					gameSettings: storedGameSettings,
					audioSettings: storedAudioSettings,
					runStats: storedRunStats,
					hasSeenOnboarding: hasSeenOnboarding
				)
			},
			saveGameSettings: { settings in
				let normalized = settings.normalized
				defaults.set(normalized.maxDepth, forKey: Keys.maxDepth)
				defaults.set(normalized.decisionTime, forKey: Keys.decisionTime)
				defaults.set(normalized.happyEndingStartPercent, forKey: Keys.happyEndingStartPercent)
			},
			saveAudioSettings: { audioSettings in
				let normalized = audioSettings.normalized
				defaults.set(normalized.effectsVolume, forKey: Keys.effectsVolume)
				defaults.set(normalized.musicVolume, forKey: Keys.musicVolume)
				defaults.set(normalized.isMuted, forKey: Keys.isMuted)
			},
			saveRunStats: { runStats in
				let normalized = runStats.normalized
				defaults.set(normalized.bestDepth, forKey: Keys.bestDepth)
				defaults.set(normalized.escapedRuns, forKey: Keys.escapedRuns)
			},
			saveHasSeenOnboarding: { hasSeenOnboarding in
				defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding)
			}
		)
	}
}
