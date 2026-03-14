import SwiftUI

#if os(macOS)
import AppKit
#endif

struct GameplayOverlayView: View {
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
				depthProgress: session.depthProgress,
				currentSeed: session.currentSeed
			)

			Spacer()

			if let decisionRatio = session.decisionRemainingRatio {
				DecisionTimerView(remainingRatio: decisionRatio)
			}

			if let summary = session.runSummary {
				RunSummaryCardView(summary: summary)
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

struct RunSummaryCardView: View {
	let summary: CaveRunSummary

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .center) {
				Label(summary.statusLabel, systemImage: summary.isSuccessful ? "sparkles" : "exclamationmark.triangle.fill")
					.font(.footnote.weight(.semibold))
					.foregroundStyle(summary.isSuccessful ? Color.green : Color.orange)
					.padding(.horizontal, 10)
					.padding(.vertical, 6)
					.background((summary.isSuccessful ? Color.green : Color.orange).opacity(0.16), in: Capsule())

				Spacer()

				Text(summary.headline)
					.font(.headline)
					.foregroundStyle(.white.opacity(0.92))
			}

			Text(summary.outcomeTitle)
				.font(.title2.bold())
				.foregroundStyle(.white)

			Text(summary.outcomeSubtitle)
				.font(.subheadline)
				.foregroundStyle(.white.opacity(0.88))

			VStack(alignment: .leading, spacing: 6) {
				Text(summary.depthLine)
					.font(.subheadline.monospacedDigit())
					.foregroundStyle(.white.opacity(0.9))

				ProgressView(value: summary.progressRatio)
					.tint(summary.isSuccessful ? .green : .orange)
			}

			HStack(spacing: 8) {
				SummaryMetricChip(
					title: "Tiempo",
					value: summary.estimatedDurationLine.replacingOccurrences(of: "Tiempo estimado: ", with: "")
				)
				SummaryMetricChip(title: "Decisiones", value: "\(summary.decisionsTaken)")
				SummaryMetricChip(title: "Seed", value: summary.seed.map { String($0) } ?? "Aleatoria")
			}

			Text(summary.recommendedNextAction)
				.font(.footnote)
				.foregroundStyle(.white.opacity(0.74))
		}
		.frame(maxWidth: 540, alignment: .leading)
		.padding(16)
		.background(
			LinearGradient(
				colors: [
					(summary.isSuccessful ? Color.green : Color.orange).opacity(0.18),
					Color.black.opacity(0.44)
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			),
			in: .rect(cornerRadius: 18)
		)
		.overlay {
			RoundedRectangle(cornerRadius: 18)
				.stroke((summary.isSuccessful ? Color.green : Color.orange).opacity(0.28), lineWidth: 1)
		}
	}
}

struct SummaryMetricChip: View {
	let title: String
	let value: String

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(title.uppercased())
				.font(.caption2.weight(.semibold))
				.foregroundStyle(.white.opacity(0.56))

			Text(value)
				.font(.footnote.monospacedDigit())
				.foregroundStyle(.white.opacity(0.92))
		}
		.padding(.horizontal, 10)
		.padding(.vertical, 8)
		.background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
	}
}

struct TopHUDView: View {
	let currentDepth: Int
	let maxDepth: Int
	let title: String
	let subtitle: String
	let depthProgress: Double
	let currentSeed: UInt64?

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

			#if DEBUG
			CurrentSeedPanelView(seed: currentSeed)
			#endif
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

#if DEBUG
struct CurrentSeedPanelView: View {
	let seed: UInt64?
	@State private var didCopy = false

	private var seedText: String {
		if let seed {
			return String(seed)
		}
		return "aleatoria"
	}

	var body: some View {
		HStack(spacing: 10) {
			Label("Seed actual: \(seedText)", systemImage: "ladybug")
				.font(.footnote.monospacedDigit())
				.foregroundStyle(.white.opacity(0.8))

			if let seed {
				Button(didCopy ? "Copiada" : "Copiar") {
					copySeed(seed)
				}
				.buttonStyle(.bordered)
				.controlSize(.small)
			}
		}
	}

	private func copySeed(_ seed: UInt64) {
		#if os(macOS)
		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		pasteboard.setString(String(seed), forType: .string)
		#endif

		didCopy = true
		Task {
			try? await Task.sleep(for: .seconds(1.2))
			didCopy = false
		}
	}
}
#endif

struct DecisionTimerView: View {
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

struct ChoicePanelView: View {
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

struct BottomActionBar: View {
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
