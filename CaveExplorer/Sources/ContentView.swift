import CaveDomain
import SwiftUI

public struct ContentView: View {
	@State private var session = CaveSession(
		config: CaveConfig(
			maxDepth: 5,
			decisionTime: 3.0,
			happyEndingStartPercent: 0.8
		)
	)
	@State private var torchPulse = 0.0

	public var body: some View {
		ZStack {
			CaveBackdropView(torchPulse: torchPulse)

			VStack(spacing: 18) {
				DepthHeaderView(currentDepth: session.currentDepth, maxDepth: session.maxDepth, progress: session.depthProgress)

				StatusCardView(title: session.titleText, subtitle: session.subtitleText)

				if let travelProgress = session.travelProgress {
					ProgressPanelView(
						title: "Avance por el tunel",
						value: travelProgress,
						tint: .orange
					)
				}

				if let decisionRatio = session.decisionRemainingRatio {
					ProgressPanelView(
						title: "Tiempo para decidir",
						value: decisionRatio,
						tint: .red
					)
				}

				ChoicePanelView(choices: session.choices) { optionIndex in
					session.choose(optionIndex: optionIndex)
				}

				Button(session.isGameOver ? "Jugar de nuevo" : "Nuevo mapa") {
					session.startNewGame()
				}
				.buttonStyle(.borderedProminent)
				.controlSize(.large)
			}
			.padding(24)
			.frame(maxWidth: 640)
		}
		.frame(minWidth: 960, minHeight: 640)
		.task {
			await runGameLoop()
		}
		.task {
			await runTorchAnimationLoop()
		}
	}

	private func runGameLoop() async {
		let frameDuration = Duration.milliseconds(50)
		let fixedDelta = 0.05

		while !Task.isCancelled {
			session.tick(deltaTime: fixedDelta)
			try? await Task.sleep(for: frameDuration)
		}
	}

	private func runTorchAnimationLoop() async {
		while !Task.isCancelled {
			withAnimation(.easeInOut(duration: 0.45)) {
				torchPulse = Double.random(in: 0...1)
			}
			try? await Task.sleep(for: .milliseconds(450))
		}
	}
}

private struct CaveBackdropView: View {
	let torchPulse: Double

	var body: some View {
		ZStack {
			LinearGradient(
				colors: [Color(red: 0.08, green: 0.09, blue: 0.12), Color(red: 0.03, green: 0.03, blue: 0.04)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)

			RadialGradient(
				colors: [
					Color(red: 0.95, green: 0.54, blue: 0.18).opacity(0.26),
					Color(red: 0.26, green: 0.15, blue: 0.08).opacity(0.22),
					.black.opacity(0.9),
				],
				center: .center,
				startRadius: 36,
				endRadius: 460
			)

			RadialGradient(
				colors: [.clear, .black.opacity(0.84)],
				center: .center,
				startRadius: 120 + (torchPulse * 30),
				endRadius: 390 + (torchPulse * 40)
			)
		}
		.ignoresSafeArea()
	}
}

private struct DepthHeaderView: View {
	let currentDepth: Int
	let maxDepth: Int
	let progress: Double

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Profundidad \(currentDepth) / \(maxDepth)")
				.font(.title2.bold())
				.foregroundStyle(.white)

			ProgressView(value: progress)
				.tint(.orange)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

private struct StatusCardView: View {
	let title: String
	let subtitle: String

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(title)
				.font(.system(.title2, design: .rounded, weight: .bold))
				.foregroundStyle(.white)

			Text(subtitle)
				.foregroundStyle(.white.opacity(0.88))
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16)
		.background(.black.opacity(0.35), in: .rect(cornerRadius: 14))
		.overlay {
			RoundedRectangle(cornerRadius: 14)
				.stroke(.white.opacity(0.15), lineWidth: 1)
		}
	}
}

private struct ProgressPanelView: View {
	let title: String
	let value: Double
	let tint: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(title)
				.font(.headline)
				.foregroundStyle(.white)

			ProgressView(value: value)
				.tint(tint)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

private struct ChoicePanelView: View {
	let choices: [CaveSession.Choice]
	let onSelect: (Int) -> Void

	var body: some View {
		VStack(spacing: 10) {
			ForEach(choices) { choice in
				Button(choice.title) {
					onSelect(choice.optionIndex)
				}
				.buttonStyle(.borderedProminent)
				.controlSize(.large)
				.frame(maxWidth: .infinity)
			}
		}
		.frame(maxWidth: .infinity)
	}
}
