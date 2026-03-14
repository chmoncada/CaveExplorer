import SwiftUI

struct StartMenuOverlayView: View {
	let settings: CaveGameSettings
	let runStats: CaveRunStats
	let recentRuns: [CaveRunRecord]
	let showOnboarding: Bool
	let selectedPreset: CaveGamePreset?
	let onSelectPreset: (CaveGamePreset) -> Void
	let onDismissOnboarding: () -> Void
	let onStart: () -> Void
	let onOpenSettings: () -> Void

	private var settingsSummary: String {
		let presetName = selectedPreset?.title ?? "Personalizado"
		let decision = settings.decisionTime.formatted(.number.precision(.fractionLength(1)))
		return "Preset: \(presetName). Profundidad \(settings.maxDepth), decision \(decision)s"
	}

	private var progressSummary: String {
		"Mejor profundidad: \(runStats.bestDepth) | Escapes: \(runStats.escapedRuns)"
	}

	var body: some View {
		VStack {
			Spacer()

			VStack(alignment: .leading, spacing: 16) {
				Text("Cave Explorer")
					.font(.system(size: 46, weight: .black, design: .rounded))
					.foregroundStyle(.white)

				Text("Explora la cueva antes de que la oscuridad te alcance.")
					.font(.title3)
					.foregroundStyle(.white.opacity(0.92))

				PresetSelectorView(
					selectedPreset: selectedPreset,
					onSelectPreset: onSelectPreset
				)

				Text(settingsSummary)
					.font(.subheadline)
					.foregroundStyle(.white.opacity(0.82))

				Text(progressSummary)
					.font(.footnote.monospacedDigit())
					.foregroundStyle(.white.opacity(0.78))

				HStack(spacing: 10) {
					HomeStatCardView(title: "Mejor profundidad", value: "\(runStats.bestDepth)", accent: .orange)
					HomeStatCardView(title: "Escapes", value: "\(runStats.escapedRuns)", accent: .green)
					HomeStatCardView(title: "Preset", value: selectedPreset?.title ?? "Custom", accent: .blue)
				}

				if !recentRuns.isEmpty {
					RecentRunsPanelView(recentRuns: recentRuns)
				}

				if showOnboarding {
					OnboardingCardView(onClose: {
						onDismissOnboarding()
					})
				}

				HStack(spacing: 10) {
					Button("Iniciar expedicion", systemImage: "play.fill") {
						onStart()
					}
					.buttonStyle(.borderedProminent)
					.controlSize(.large)

					Button("Ajustes", systemImage: "slider.horizontal.3") {
						onOpenSettings()
					}
					.buttonStyle(.bordered)
					.controlSize(.large)
				}
			}
			.frame(maxWidth: 620, alignment: .leading)
			.padding(24)
			.background(.black.opacity(0.44), in: .rect(cornerRadius: 18))
			.overlay {
				RoundedRectangle(cornerRadius: 18)
					.stroke(.white.opacity(0.18), lineWidth: 1)
			}

			Spacer()
		}
		.padding(22)
	}
}

struct RecentRunsPanelView: View {
	let recentRuns: [CaveRunRecord]

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("Runs recientes")
				.font(.headline)
				.foregroundStyle(.white)

			ForEach(recentRuns.prefix(CaveRunRecord.homeVisibleLimit)) { run in
				VStack(alignment: .leading, spacing: 2) {
					Text("\(run.outcomeTitle) - \(run.progressPercent)%")
						.font(.subheadline)
						.foregroundStyle(.white.opacity(0.9))

					Text("\(run.durationLine) - \(run.seedLine)")
						.font(.footnote.monospacedDigit())
						.foregroundStyle(.white.opacity(0.75))
				}
			}
		}
		.padding(12)
		.background(.black.opacity(0.3), in: .rect(cornerRadius: 12))
		.overlay {
			RoundedRectangle(cornerRadius: 12)
				.stroke(.white.opacity(0.16), lineWidth: 1)
		}
	}
}

struct OnboardingCardView: View {
	let onClose: () -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Como jugar")
				.font(.headline)
				.foregroundStyle(.white)

			OnboardingStepRow(icon: "play.circle.fill", text: "Inicia la expedicion y mantente atento al HUD.")
			OnboardingStepRow(icon: "timer", text: "Cada cruce tiene tiempo limite; dudar demasiado atrae al monstruo.")
			OnboardingStepRow(icon: "sparkles", text: "Llega al portal para escapar y mejorar tu historial.")

			Button("Entendido") {
				onClose()
			}
			.buttonStyle(.bordered)
		}
		.padding(12)
		.background(.black.opacity(0.3), in: .rect(cornerRadius: 12))
		.overlay {
			RoundedRectangle(cornerRadius: 12)
				.stroke(.white.opacity(0.16), lineWidth: 1)
		}
	}
}

struct HomeStatCardView: View {
	let title: String
	let value: String
	let accent: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(title)
				.font(.caption)
				.foregroundStyle(.white.opacity(0.7))

			Text(value)
				.font(.title3.bold())
				.foregroundStyle(.white)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
		.overlay {
			RoundedRectangle(cornerRadius: 12)
				.stroke(accent.opacity(0.28), lineWidth: 1)
		}
	}
}

struct OnboardingStepRow: View {
	let icon: String
	let text: String

	var body: some View {
		HStack(alignment: .top, spacing: 10) {
			Image(systemName: icon)
				.foregroundStyle(.orange)
				.frame(width: 18)

			Text(text)
				.font(.subheadline)
				.foregroundStyle(.white.opacity(0.9))
		}
	}
}

struct PresetSelectorView: View {
	let selectedPreset: CaveGamePreset?
	let onSelectPreset: (CaveGamePreset) -> Void

	var body: some View {
		HStack(spacing: 8) {
			ForEach(CaveGamePreset.allCases) { preset in
				if selectedPreset == preset {
					Button(preset.title) {
						onSelectPreset(preset)
					}
					.buttonStyle(.borderedProminent)
				} else {
					Button(preset.title) {
						onSelectPreset(preset)
					}
					.buttonStyle(.bordered)
				}
			}
		}
	}
}
