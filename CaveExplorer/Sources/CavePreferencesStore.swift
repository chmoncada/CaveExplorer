import Foundation

struct CavePreferencesSnapshot: Equatable {
	var gameSettings: CaveGameSettings
	var audioSettings: CaveAudioSettings
}

struct CavePreferencesStore {
	private enum Keys {
		static let maxDepth = "cave.settings.maxDepth"
		static let decisionTime = "cave.settings.decisionTime"
		static let happyEndingStartPercent = "cave.settings.happyEndingStartPercent"
		static let effectsVolume = "cave.audio.effectsVolume"
		static let musicVolume = "cave.audio.musicVolume"
		static let isMuted = "cave.audio.isMuted"
	}

	var load: () -> CavePreferencesSnapshot
	var saveGameSettings: (CaveGameSettings) -> Void
	var saveAudioSettings: (CaveAudioSettings) -> Void

	static let live = userDefaults()

	static func userDefaults(_ defaults: UserDefaults = .standard) -> CavePreferencesStore {
		CavePreferencesStore(
			load: {
				let defaultGameSettings = CaveGameSettings.default
				let defaultAudioSettings = CaveAudioSettings.default

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

				return CavePreferencesSnapshot(
					gameSettings: storedGameSettings,
					audioSettings: storedAudioSettings
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
			}
		)
	}
}
