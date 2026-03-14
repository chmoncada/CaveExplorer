import Foundation

struct CavePreferencesSnapshot: Equatable {
	var gameSettings: CaveGameSettings
	var audioSettings: CaveAudioSettings
	var runStats: CaveRunStats
	var recentRuns: [CaveRunRecord]
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
		static let recentRunsData = "cave.stats.recentRunsData"
		static let hasSeenOnboarding = "cave.ui.hasSeenOnboarding"
	}

	var load: () -> CavePreferencesSnapshot
	var saveGameSettings: (CaveGameSettings) -> Void
	var saveAudioSettings: (CaveAudioSettings) -> Void
	var saveRunStats: (CaveRunStats) -> Void
	var saveRecentRuns: ([CaveRunRecord]) -> Void
	var saveHasSeenOnboarding: (Bool) -> Void

	static let live = userDefaults()

	static func userDefaults(_ defaults: UserDefaults = .standard) -> CavePreferencesStore {
		CavePreferencesStore(
			load: {
				loadSnapshot(from: defaults)
			},
			saveGameSettings: { settings in
				saveGameSettings(settings, into: defaults)
			},
			saveAudioSettings: { audioSettings in
				saveAudioSettings(audioSettings, into: defaults)
			},
			saveRunStats: { runStats in
				saveRunStats(runStats, into: defaults)
			},
			saveRecentRuns: { recentRuns in
				saveRecentRuns(recentRuns, into: defaults)
			},
			saveHasSeenOnboarding: { hasSeenOnboarding in
				defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding)
			}
		)
	}

	private static func loadSnapshot(from defaults: UserDefaults) -> CavePreferencesSnapshot {
		CavePreferencesSnapshot(
			gameSettings: loadGameSettings(from: defaults),
			audioSettings: loadAudioSettings(from: defaults),
			runStats: loadRunStats(from: defaults),
			recentRuns: loadRecentRuns(from: defaults),
			hasSeenOnboarding: defaults.object(forKey: Keys.hasSeenOnboarding) as? Bool ?? false
		)
	}

	private static func loadGameSettings(from defaults: UserDefaults) -> CaveGameSettings {
		let defaultGameSettings = CaveGameSettings.default
		return CaveGameSettings(
			maxDepth: defaults.object(forKey: Keys.maxDepth) as? Int ?? defaultGameSettings.maxDepth,
			decisionTime: defaults.object(forKey: Keys.decisionTime) as? Double ?? defaultGameSettings.decisionTime,
			happyEndingStartPercent:
				defaults.object(forKey: Keys.happyEndingStartPercent) as? Double
					?? defaultGameSettings.happyEndingStartPercent
		).normalized
	}

	private static func loadAudioSettings(from defaults: UserDefaults) -> CaveAudioSettings {
		let defaultAudioSettings = CaveAudioSettings.default
		return CaveAudioSettings(
			effectsVolume:
				defaults.object(forKey: Keys.effectsVolume) as? Double
					?? defaultAudioSettings.effectsVolume,
			musicVolume:
				defaults.object(forKey: Keys.musicVolume) as? Double
					?? defaultAudioSettings.musicVolume,
			isMuted: defaults.object(forKey: Keys.isMuted) as? Bool ?? defaultAudioSettings.isMuted
		).normalized
	}

	private static func loadRunStats(from defaults: UserDefaults) -> CaveRunStats {
		let defaultRunStats = CaveRunStats.empty
		return CaveRunStats(
			bestDepth: defaults.object(forKey: Keys.bestDepth) as? Int ?? defaultRunStats.bestDepth,
			escapedRuns: defaults.object(forKey: Keys.escapedRuns) as? Int ?? defaultRunStats.escapedRuns
		).normalized
	}

	private static func saveGameSettings(_ settings: CaveGameSettings, into defaults: UserDefaults) {
		let normalized = settings.normalized
		defaults.set(normalized.maxDepth, forKey: Keys.maxDepth)
		defaults.set(normalized.decisionTime, forKey: Keys.decisionTime)
		defaults.set(normalized.happyEndingStartPercent, forKey: Keys.happyEndingStartPercent)
	}

	private static func saveAudioSettings(_ audioSettings: CaveAudioSettings, into defaults: UserDefaults) {
		let normalized = audioSettings.normalized
		defaults.set(normalized.effectsVolume, forKey: Keys.effectsVolume)
		defaults.set(normalized.musicVolume, forKey: Keys.musicVolume)
		defaults.set(normalized.isMuted, forKey: Keys.isMuted)
	}

	private static func saveRunStats(_ runStats: CaveRunStats, into defaults: UserDefaults) {
		let normalized = runStats.normalized
		defaults.set(normalized.bestDepth, forKey: Keys.bestDepth)
		defaults.set(normalized.escapedRuns, forKey: Keys.escapedRuns)
	}

	private static func loadRecentRuns(from defaults: UserDefaults) -> [CaveRunRecord] {
		guard let data = defaults.data(forKey: Keys.recentRunsData) else { return [] }
		guard let runs = try? JSONDecoder().decode([CaveRunRecord].self, from: data) else { return [] }
		return Array(runs.prefix(CaveRunRecord.storedHistoryLimit))
	}

	private static func saveRecentRuns(_ recentRuns: [CaveRunRecord], into defaults: UserDefaults) {
		let cappedRuns = Array(recentRuns.prefix(CaveRunRecord.storedHistoryLimit))
		guard let encoded = try? JSONEncoder().encode(cappedRuns) else { return }
		defaults.set(encoded, forKey: Keys.recentRunsData)
	}
}
