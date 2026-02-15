import Foundation

struct CaveAudioSettings: Equatable {
	static let volumeRange: ClosedRange<Double> = 0...1
	static let `default` = CaveAudioSettings()

	var effectsVolume: Double
	var musicVolume: Double
	var isMuted: Bool

	init(
		effectsVolume: Double = 0.9,
		musicVolume: Double = 0.55,
		isMuted: Bool = false
	) {
		self.effectsVolume = effectsVolume
		self.musicVolume = musicVolume
		self.isMuted = isMuted
	}

	var normalized: CaveAudioSettings {
		CaveAudioSettings(
			effectsVolume: clampAudioValue(effectsVolume),
			musicVolume: clampAudioValue(musicVolume),
			isMuted: isMuted
		)
	}
}

private func clampAudioValue(_ value: Double) -> Double {
	min(CaveAudioSettings.volumeRange.upperBound, max(CaveAudioSettings.volumeRange.lowerBound, value))
}
