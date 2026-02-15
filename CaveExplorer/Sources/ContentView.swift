import CaveDomain
import SwiftUI

public struct ContentView: View {
	@State private var settings = CaveGameSettings.default
	@State private var session = CaveSession(config: CaveGameSettings.default.caveConfig)
	@State private var torchPulse = 0.0
	@State private var gameFlow: GameFlow = .home
	@State private var presentedSheet: PresentedSheet?

	private let tunnelBuilder = CaveTunnelFrameBuilder(segmentCount: 11)
	private let atmosphereBuilder = CaveAtmosphereFrameBuilder(fogBandCount: 4, dustCount: 36, batCount: 3)

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
				SettingsSheetView(settings: $settings) {
					presentedSheet = nil
				}
			}
		}
		.task {
			await runGameLoop()
		}
		.task {
			await runTorchAnimationLoop()
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
		gameFlow = .playing
	}

	private func returnHome() {
		gameFlow = .home
	}

	private func runGameLoop() async {
		let frameDuration = Duration.milliseconds(50)
		let fixedDelta = 0.05

		while !Task.isCancelled {
			if gameFlow == .playing {
				session.tick(deltaTime: fixedDelta)
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

private struct GameplayOverlayView: View {
	let session: CaveSession
	let onChoose: (Int) -> Void
	let onNewMap: () -> Void
	let onReturnHome: () -> Void

	var body: some View {
		VStack(spacing: 14) {
			TopHUDView(
				currentDepth: session.currentDepth,
				maxDepth: session.maxDepth,
				title: session.titleText,
				subtitle: session.subtitleText,
				depthProgress: session.depthProgress
			)

			Spacer()

			if let decisionRatio = session.decisionRemainingRatio {
				DecisionTimerView(remainingRatio: decisionRatio)
			}

			ChoicePanelView(choices: session.choices) { optionIndex in
				onChoose(optionIndex)
			}

			BottomActionBar(
				isGameOver: session.isGameOver,
				onNewMap: onNewMap,
				onReturnHome: onReturnHome
			)
		}
	}
}

private struct StartMenuOverlayView: View {
	let settings: CaveGameSettings
	let onStart: () -> Void
	let onOpenSettings: () -> Void

	private var settingsSummary: String {
		"Ajustes activos: profundidad \(settings.maxDepth), "
			+ "decision \(settings.decisionTime.formatted(.number.precision(.fractionLength(1))))s"
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

				Text(settingsSummary)
					.font(.subheadline)
					.foregroundStyle(.white.opacity(0.82))

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
			.frame(maxWidth: 540, alignment: .leading)
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

private struct SettingsSheetView: View {
	@Binding var settings: CaveGameSettings
	let onClose: () -> Void

	var body: some View {
		VStack(spacing: 16) {
			SettingsPanelView(settings: $settings)

			HStack {
				Spacer()

				Button("Cerrar") {
					onClose()
				}
				.buttonStyle(.borderedProminent)
			}
		}
		.padding(20)
		.frame(minWidth: 480)
	}
}

private struct TopHUDView: View {
	let currentDepth: Int
	let maxDepth: Int
	let title: String
	let subtitle: String
	let depthProgress: Double

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Profundidad \(currentDepth) / \(maxDepth)")
				.font(.headline)
				.foregroundStyle(.white)

			ProgressView(value: depthProgress)
				.tint(.orange)

			Text(title)
				.font(.title3.bold())
				.foregroundStyle(.white)

			Text(subtitle)
				.font(.subheadline)
				.foregroundStyle(.white.opacity(0.9))
		}
		.frame(maxWidth: 540, alignment: .leading)
		.padding(16)
		.background(.black.opacity(0.34), in: .rect(cornerRadius: 16))
		.overlay {
			RoundedRectangle(cornerRadius: 16)
				.stroke(.white.opacity(0.18), lineWidth: 1)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

private struct DecisionTimerView: View {
	let remainingRatio: Double

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("Decide rapido")
				.font(.headline)
				.foregroundStyle(.white)

			GeometryReader { proxy in
				let width = proxy.size.width * max(0, min(1, remainingRatio))
				ZStack(alignment: .leading) {
					RoundedRectangle(cornerRadius: 8)
						.fill(.black.opacity(0.35))

					RoundedRectangle(cornerRadius: 8)
						.fill(.red.gradient)
						.frame(width: width)
				}
			}
			.frame(height: 14)
		}
		.frame(maxWidth: 440)
		.padding(.horizontal, 14)
		.padding(.vertical, 10)
		.background(.black.opacity(0.34), in: .rect(cornerRadius: 14))
		.overlay {
			RoundedRectangle(cornerRadius: 14)
				.stroke(.white.opacity(0.18), lineWidth: 1)
		}
	}
}

private struct ChoicePanelView: View {
	let choices: [CaveSession.Choice]
	let onSelect: (Int) -> Void

	var body: some View {
		HStack(spacing: 10) {
			ForEach(choices) { choice in
				Button {
					onSelect(choice.optionIndex)
				} label: {
					Label(choice.title, systemImage: symbolName(for: choice.optionIndex, total: choices.count))
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
				.controlSize(.large)
			}
		}
		.frame(maxWidth: 540)
		.opacity(choices.isEmpty ? 0 : 1)
	}

	private func symbolName(for index: Int, total: Int) -> String {
		switch total {
		case 2:
			return index == 0 ? "arrow.turn.up.left" : "arrow.turn.up.right"
		case 3:
			switch index {
			case 0:
				return "arrow.turn.up.left"
			case 1:
				return "arrow.up"
			default:
				return "arrow.turn.up.right"
			}
		default:
			return "arrow.up"
		}
	}
}

private struct SettingsPanelView: View {
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

private struct BottomActionBar: View {
	let isGameOver: Bool
	let onNewMap: () -> Void
	let onReturnHome: () -> Void

	var body: some View {
		HStack {
			Text(isGameOver ? "La expedicion termino" : "Exploracion en curso")
				.foregroundStyle(.white.opacity(0.9))

			Spacer()

			Button("Inicio") {
				onReturnHome()
			}
			.buttonStyle(.bordered)

			Button(isGameOver ? "Reintentar" : "Nuevo mapa") {
				onNewMap()
			}
			.buttonStyle(.borderedProminent)
		}
		.frame(maxWidth: 540)
		.padding(12)
		.background(.black.opacity(0.34), in: .rect(cornerRadius: 14))
		.overlay {
			RoundedRectangle(cornerRadius: 14)
				.stroke(.white.opacity(0.18), lineWidth: 1)
		}
	}
}
