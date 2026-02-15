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

	private let tunnelBuilder = CaveTunnelFrameBuilder(segmentCount: 11)

	public var body: some View {
		ZStack {
			CaveRunSceneView(
				frameBuilder: tunnelBuilder,
				travelProgress: session.travelProgress ?? 0,
				decisionRemainingRatio: session.decisionRemainingRatio,
				decisionChoiceCount: session.choices.count,
				isGameOver: session.isGameOver,
				torchPulse: torchPulse
			)

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
					session.choose(optionIndex: optionIndex)
				}

				BottomActionBar(isGameOver: session.isGameOver) {
					session.startNewGame()
				}
			}
			.padding(22)
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
			withAnimation(.easeInOut(duration: 0.35)) {
				torchPulse = Double.random(in: 0...1)
			}
			try? await Task.sleep(for: .milliseconds(350))
		}
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

private struct BottomActionBar: View {
	let isGameOver: Bool
	let onNewMap: () -> Void

	var body: some View {
		HStack {
			Text(isGameOver ? "La expedicion termino" : "Exploracion en curso")
				.foregroundStyle(.white.opacity(0.9))

			Spacer()

			Button(isGameOver ? "Jugar de nuevo" : "Nuevo mapa") {
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

private struct CaveRunSceneView: View {
	let frameBuilder: CaveTunnelFrameBuilder
	let travelProgress: Double
	let decisionRemainingRatio: Double?
	let decisionChoiceCount: Int
	let isGameOver: Bool
	let torchPulse: Double

	var body: some View {
		TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
			Canvas(rendersAsynchronously: true) { context, size in
				let elapsed = timeline.date.timeIntervalSinceReferenceDate
				let frame = frameBuilder.makeFrame(
					in: size,
					elapsed: elapsed,
					travelProgress: travelProgress,
					pulse: torchPulse
				)

				drawBackdrop(into: &context, size: size)
				drawTunnel(into: &context, frame: frame)
				drawTorchGlow(into: &context, frame: frame, size: size)

				if decisionChoiceCount > 0 {
					drawDecisionBeacons(
						into: &context,
						frame: frame,
						size: size,
						elapsed: elapsed
					)
				}

				if isGameOver {
					drawGameOverMask(into: &context, size: size)
				}
			}
		}
		.ignoresSafeArea()
	}

	private func drawBackdrop(into context: inout GraphicsContext, size: CGSize) {
		let rect = CGRect(origin: .zero, size: size)
		context.fill(
			Path(rect),
			with: .linearGradient(
				Gradient(colors: [
					Color(red: 0.07, green: 0.07, blue: 0.08),
					Color(red: 0.03, green: 0.03, blue: 0.04),
				]),
				startPoint: CGPoint(x: size.width * 0.2, y: 0),
				endPoint: CGPoint(x: size.width * 0.8, y: size.height)
			)
		)
	}

	private func drawTunnel(into context: inout GraphicsContext, frame: CaveTunnelFrame) {
		for layer in frame.layers {
			let outer = layer.outerRect
			let inner = layer.innerRect
			let intensity = layer.intensity

			let outerTopLeft = CGPoint(x: outer.minX, y: outer.minY)
			let outerTopRight = CGPoint(x: outer.maxX, y: outer.minY)
			let outerBottomLeft = CGPoint(x: outer.minX, y: outer.maxY)
			let outerBottomRight = CGPoint(x: outer.maxX, y: outer.maxY)

			let innerTopLeft = CGPoint(x: inner.minX, y: inner.minY)
			let innerTopRight = CGPoint(x: inner.maxX, y: inner.minY)
			let innerBottomLeft = CGPoint(x: inner.minX, y: inner.maxY)
			let innerBottomRight = CGPoint(x: inner.maxX, y: inner.maxY)

			let leftWall = quadPath(outerTopLeft, outerBottomLeft, innerBottomLeft, innerTopLeft)
			let rightWall = quadPath(outerTopRight, outerBottomRight, innerBottomRight, innerTopRight)
			let roof = quadPath(outerTopLeft, outerTopRight, innerTopRight, innerTopLeft)
			let floor = quadPath(outerBottomLeft, outerBottomRight, innerBottomRight, innerBottomLeft)

			context.fill(leftWall, with: .color(Color(red: 0.18, green: 0.14, blue: 0.11).opacity(0.12 + (0.22 * intensity))))
			context.fill(
				rightWall, with: .color(Color(red: 0.16, green: 0.12, blue: 0.10).opacity(0.12 + (0.22 * intensity))))
			context.fill(roof, with: .color(Color(red: 0.11, green: 0.10, blue: 0.10).opacity(0.10 + (0.16 * intensity))))
			context.fill(floor, with: .color(Color(red: 0.12, green: 0.09, blue: 0.08).opacity(0.10 + (0.24 * intensity))))

			let innerRing = Path(roundedRect: inner, cornerRadius: max(4, inner.width * 0.03))
			context.stroke(innerRing, with: .color(.white.opacity(0.04 + (0.05 * intensity))), lineWidth: 1)
		}
	}

	private func drawTorchGlow(into context: inout GraphicsContext, frame: CaveTunnelFrame, size: CGSize) {
		let center = CGPoint(
			x: frame.layers.last?.innerRect.midX ?? (size.width * 0.5),
			y: frame.layers.last?.innerRect.midY ?? (size.height * 0.55)
		)

		let torchRect = CGRect(
			x: center.x - frame.torchRadius,
			y: center.y - frame.torchRadius,
			width: frame.torchRadius * 2,
			height: frame.torchRadius * 2
		)

		var glowContext = context
		glowContext.blendMode = .screen
		glowContext.fill(
			Path(ellipseIn: torchRect),
			with: .radialGradient(
				Gradient(colors: [
					Color(red: 0.98, green: 0.64, blue: 0.32).opacity(0.35),
					Color(red: 0.48, green: 0.24, blue: 0.12).opacity(0.12),
					.clear,
				]),
				center: center,
				startRadius: 1,
				endRadius: frame.torchRadius
			)
		)

		let vignetteRect = CGRect(origin: .zero, size: size)
		context.fill(
			Path(vignetteRect),
			with: .radialGradient(
				Gradient(colors: [.clear, .black.opacity(0.85)]),
				center: center,
				startRadius: frame.torchRadius * 0.32,
				endRadius: max(size.width, size.height) * 0.75
			)
		)
	}

	private func drawDecisionBeacons(
		into context: inout GraphicsContext,
		frame: CaveTunnelFrame,
		size: CGSize,
		elapsed: TimeInterval
	) {
		let choiceCount = decisionChoiceCount
		let remainingRatio = decisionRemainingRatio ?? 1
		let spacing = min(size.width * 0.18, 150)
		let baseY = frame.horizonY + (size.height * 0.11)
		let urgency = 1 - max(0, min(1, remainingRatio))
		let pulse = 0.75 + (0.25 * sin(elapsed * 9)) + (urgency * 0.45)

		for index in 0..<choiceCount {
			let normalizedOffset = CGFloat(index) - (CGFloat(choiceCount - 1) * 0.5)
			let center = CGPoint(
				x: (size.width * 0.5) + (normalizedOffset * spacing),
				y: baseY
			)
			let radius = 13 + (CGFloat(pulse) * 8)

			let beaconRect = CGRect(
				x: center.x - radius,
				y: center.y - radius,
				width: radius * 2,
				height: radius * 2
			)

			context.fill(
				Path(ellipseIn: beaconRect),
				with: .radialGradient(
					Gradient(colors: [
						Color(red: 1.0, green: 0.65, blue: 0.30).opacity(0.55),
						Color(red: 0.85, green: 0.30, blue: 0.18).opacity(0.2),
						.clear,
					]),
					center: center,
					startRadius: 1,
					endRadius: radius
				)
			)

			context.draw(
				Text("\(index + 1)").font(.system(size: 14, weight: .bold)).foregroundStyle(.white),
				at: center
			)
		}
	}

	private func drawGameOverMask(into context: inout GraphicsContext, size: CGSize) {
		context.fill(
			Path(CGRect(origin: .zero, size: size)),
			with: .color(.black.opacity(0.35))
		)
	}

	private func quadPath(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Path {
		var path = Path()
		path.move(to: p1)
		path.addLine(to: p2)
		path.addLine(to: p3)
		path.addLine(to: p4)
		path.closeSubpath()
		return path
	}
}
