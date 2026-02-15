import SwiftUI

struct CaveSettingsSheetView: View {
	@Binding var settings: CaveGameSettings
	@Binding var audioSettings: CaveAudioSettings
	let onSettingsChanged: (CaveGameSettings) -> Void
	let onClose: () -> Void

	var body: some View {
		VStack(spacing: 16) {
			CaveGameSettingsPanelView(settings: $settings)
			CaveAudioSettingsPanelView(audioSettings: $audioSettings)

			HStack {
				Spacer()

				Button("Cerrar") {
					onClose()
				}
				.buttonStyle(.borderedProminent)
			}
		}
		.padding(20)
		.frame(minWidth: 520)
		.onChange(of: settings) { _, newSettings in
			onSettingsChanged(newSettings)
		}
	}
}

private struct CaveGameSettingsPanelView: View {
	@Binding var settings: CaveGameSettings

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Ajustes de partida")
				.font(.headline)
				.foregroundStyle(.white)

			HStack {
				Text("Profundidad: \(settings.maxDepth)")
					.foregroundStyle(.white.opacity(0.9))

				Spacer()

				Stepper("Profundidad", value: $settings.maxDepth, in: CaveGameSettings.depthRange)
					.labelsHidden()
			}

			VStack(alignment: .leading, spacing: 4) {
				Text(
					"Tiempo de decision: \(settings.decisionTime, format: .number.precision(.fractionLength(1)))s"
				)
				.foregroundStyle(.white.opacity(0.9))

				Slider(
					value: $settings.decisionTime,
					in: CaveGameSettings.decisionTimeRange,
					step: 0.5
				)
			}

			VStack(alignment: .leading, spacing: 4) {
				Text(
					"Final feliz desde: \(Int(settings.happyEndingStartPercent * 100), format: .number)%"
				)
				.foregroundStyle(.white.opacity(0.9))

				Slider(
					value: $settings.happyEndingStartPercent,
					in: CaveGameSettings.happyEndingStartPercentRange,
					step: 0.05
				)
			}
		}
		.frame(maxWidth: 540, alignment: .leading)
		.padding(12)
		.background(.black.opacity(0.34), in: .rect(cornerRadius: 14))
		.overlay {
			RoundedRectangle(cornerRadius: 14)
				.stroke(.white.opacity(0.18), lineWidth: 1)
		}
	}
}

private struct CaveAudioSettingsPanelView: View {
	@Binding var audioSettings: CaveAudioSettings

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Audio")
				.font(.headline)
				.foregroundStyle(.white)

			Toggle("Silenciar", isOn: $audioSettings.isMuted)
				.foregroundStyle(.white.opacity(0.9))

			VStack(alignment: .leading, spacing: 4) {
				Text("Volumen musica: \(Int(audioSettings.musicVolume * 100), format: .number)%")
					.foregroundStyle(.white.opacity(0.9))

				Slider(
					value: $audioSettings.musicVolume,
					in: CaveAudioSettings.volumeRange
				)
			}

			VStack(alignment: .leading, spacing: 4) {
				Text("Volumen efectos: \(Int(audioSettings.effectsVolume * 100), format: .number)%")
					.foregroundStyle(.white.opacity(0.9))

				Slider(
					value: $audioSettings.effectsVolume,
					in: CaveAudioSettings.volumeRange
				)
			}
		}
		.frame(maxWidth: 540, alignment: .leading)
		.padding(12)
		.background(.black.opacity(0.34), in: .rect(cornerRadius: 14))
		.overlay {
			RoundedRectangle(cornerRadius: 14)
				.stroke(.white.opacity(0.18), lineWidth: 1)
		}
	}
}
