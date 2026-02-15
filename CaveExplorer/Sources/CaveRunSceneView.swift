import Foundation
import SwiftUI

struct CaveRunSceneView: View {
	let tunnelBuilder: CaveTunnelFrameBuilder
	let atmosphereBuilder: CaveAtmosphereFrameBuilder
	let travelProgress: Double
	let depthProgress: Double
	let decisionRemainingRatio: Double?
	let decisionChoiceCount: Int
	let isGameOver: Bool
	let torchPulse: Double

	var body: some View {
		TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
			Canvas(rendersAsynchronously: true) { context, size in
				let elapsed = timeline.date.timeIntervalSinceReferenceDate
				let urgency = decisionRemainingRatio.map { 1 - max(0, min(1, $0)) } ?? 0

				let tunnelFrame = tunnelBuilder.makeFrame(
					in: size,
					elapsed: elapsed,
					travelProgress: travelProgress,
					depthProgress: depthProgress,
					urgency: urgency,
					pulse: torchPulse
				)

				let atmosphereFrame = atmosphereBuilder.makeFrame(
					in: size,
					elapsed: elapsed,
					travelProgress: travelProgress,
					torchPulse: torchPulse,
					urgency: urgency
				)

				drawBackdrop(into: &context, size: size)
				drawFog(into: &context, frame: atmosphereFrame)
				drawTunnel(into: &context, frame: tunnelFrame)
				drawDust(into: &context, frame: atmosphereFrame)
				drawBats(into: &context, frame: atmosphereFrame)
				drawTorchGlow(into: &context, frame: tunnelFrame, size: size, urgency: urgency)
				drawTorchHand(into: &context, frame: tunnelFrame, elapsed: elapsed, urgency: urgency)
				drawThreatPulse(into: &context, size: size, elapsed: elapsed, urgency: urgency)

				if decisionChoiceCount > 0 {
					drawDecisionBeacons(
						into: &context,
						frame: tunnelFrame,
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
}

extension CaveRunSceneView {
	fileprivate func drawBackdrop(into context: inout GraphicsContext, size: CGSize) {
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

	fileprivate func drawFog(into context: inout GraphicsContext, frame: CaveAtmosphereFrame) {
		for fogBand in frame.fogBands {
			let fogPath = Path(roundedRect: fogBand.rect, cornerRadius: fogBand.rect.height * 0.5)
			context.fill(
				fogPath,
				with: .linearGradient(
					Gradient(colors: [
						Color(red: 0.62, green: 0.56, blue: 0.52).opacity(fogBand.opacity * 0.5),
						Color(red: 0.38, green: 0.36, blue: 0.34).opacity(fogBand.opacity),
						Color(red: 0.20, green: 0.20, blue: 0.22).opacity(fogBand.opacity * 0.3),
					]),
					startPoint: CGPoint(x: fogBand.rect.minX, y: fogBand.rect.midY),
					endPoint: CGPoint(x: fogBand.rect.maxX, y: fogBand.rect.midY)
				)
			)
		}
	}

	fileprivate func drawTunnel(into context: inout GraphicsContext, frame: CaveTunnelFrame) {
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

			context.fill(
				leftWall,
				with: .color(Color(red: 0.18, green: 0.14, blue: 0.11).opacity(0.12 + (0.22 * intensity)))
			)
			context.fill(
				rightWall,
				with: .color(Color(red: 0.16, green: 0.12, blue: 0.10).opacity(0.12 + (0.22 * intensity)))
			)
			context.fill(
				roof,
				with: .color(Color(red: 0.11, green: 0.10, blue: 0.10).opacity(0.10 + (0.16 * intensity)))
			)
			context.fill(
				floor,
				with: .color(Color(red: 0.12, green: 0.09, blue: 0.08).opacity(0.10 + (0.24 * intensity)))
			)

			let innerRing = Path(roundedRect: inner, cornerRadius: max(4, inner.width * 0.03))
			context.stroke(innerRing, with: .color(.white.opacity(0.04 + (0.05 * intensity))), lineWidth: 1)
		}
	}

	fileprivate func drawDust(into context: inout GraphicsContext, frame: CaveAtmosphereFrame) {
		for particle in frame.dustParticles {
			let rect = CGRect(
				x: particle.center.x - particle.radius,
				y: particle.center.y - particle.radius,
				width: particle.radius * 2,
				height: particle.radius * 2
			)
			context.fill(
				Path(ellipseIn: rect),
				with: .color(.white.opacity(particle.opacity))
			)
		}
	}

	fileprivate func drawBats(into context: inout GraphicsContext, frame: CaveAtmosphereFrame) {
		for bat in frame.bats {
			let wingSpread = 12 * bat.scale
			let wingLift = CGFloat(sin(bat.flapPhase)) * (4 * bat.scale)
			let bodyHeight = 6 * bat.scale

			let batPath = buildBatPath(
				center: bat.center,
				wingSpread: wingSpread,
				wingLift: wingLift,
				bodyHeight: bodyHeight
			)

			context.fill(batPath, with: .color(Color.black.opacity(0.46 + bat.opacity)))
		}
	}

	fileprivate func drawTorchGlow(
		into context: inout GraphicsContext,
		frame: CaveTunnelFrame,
		size: CGSize,
		urgency: Double
	) {
		let sceneCenter = CGPoint(
			x: frame.layers.last?.innerRect.midX ?? (size.width * 0.5),
			y: frame.layers.last?.innerRect.midY ?? (size.height * 0.55)
		)
		let center = mix(sceneCenter, frame.torchAnchor, amount: 0.22)
		let urgencyBoost = max(0, min(1, urgency))

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
					Color(red: 0.98, green: 0.64, blue: 0.32).opacity(0.35 + (0.12 * urgencyBoost)),
					Color(red: 0.48, green: 0.24, blue: 0.12).opacity(0.12 + (0.08 * urgencyBoost)),
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
				Gradient(colors: [.clear, .black.opacity(0.84 + (0.08 * urgencyBoost))]),
				center: center,
				startRadius: frame.torchRadius * 0.32,
				endRadius: max(size.width, size.height) * 0.75
			)
		)
	}

	fileprivate func drawTorchHand(
		into context: inout GraphicsContext,
		frame: CaveTunnelFrame,
		elapsed: TimeInterval,
		urgency: Double
	) {
		let bob = CGFloat(sin(elapsed * 8.6)) * 4 + (frame.cameraOffset.height * 0.30)
		let anchor = CGPoint(
			x: frame.torchAnchor.x + (frame.cameraOffset.width * 0.20),
			y: frame.torchAnchor.y + bob
		)
		let torchTip = CGPoint(
			x: anchor.x - 66,
			y: anchor.y - 106
		)
		let shaftHalfWidth: CGFloat = 8
		let shaftNormal = normalizedPerpendicular(from: anchor, to: torchTip)

		let shaftPath = quadPath(
			CGPoint(x: anchor.x + (shaftNormal.x * shaftHalfWidth), y: anchor.y + (shaftNormal.y * shaftHalfWidth)),
			CGPoint(x: anchor.x - (shaftNormal.x * shaftHalfWidth), y: anchor.y - (shaftNormal.y * shaftHalfWidth)),
			CGPoint(x: torchTip.x - (shaftNormal.x * shaftHalfWidth), y: torchTip.y - (shaftNormal.y * shaftHalfWidth)),
			CGPoint(x: torchTip.x + (shaftNormal.x * shaftHalfWidth), y: torchTip.y + (shaftNormal.y * shaftHalfWidth))
		)

		context.fill(shaftPath, with: .color(Color(red: 0.34, green: 0.24, blue: 0.15).opacity(0.92)))

		let handRect = CGRect(x: anchor.x - 26, y: anchor.y - 30, width: 46, height: 38)
		context.fill(
			Path(roundedRect: handRect, cornerRadius: 14),
			with: .color(Color(red: 0.42, green: 0.30, blue: 0.23).opacity(0.95))
		)

		let urgencyBoost = max(0, min(1, urgency))
		let flamePulse = CGFloat(0.5 + (0.5 * sin(elapsed * 11.2)))
		let flameRadius = 14 + (flamePulse * 9) + (CGFloat(urgencyBoost) * 7)
		let flameCenter = CGPoint(x: torchTip.x - 3, y: torchTip.y - 6)
		let flameRect = CGRect(
			x: flameCenter.x - flameRadius,
			y: flameCenter.y - flameRadius,
			width: flameRadius * 2,
			height: flameRadius * 2
		)

		var flameContext = context
		flameContext.blendMode = .screen
		flameContext.fill(
			Path(ellipseIn: flameRect),
			with: .radialGradient(
				Gradient(colors: [
					Color(red: 1.0, green: 0.74, blue: 0.33).opacity(0.85),
					Color(red: 0.96, green: 0.36, blue: 0.18).opacity(0.46 + (0.18 * urgencyBoost)),
					.clear,
				]),
				center: flameCenter,
				startRadius: 1,
				endRadius: flameRadius
			)
		)
	}

	fileprivate func drawThreatPulse(
		into context: inout GraphicsContext,
		size: CGSize,
		elapsed: TimeInterval,
		urgency: Double
	) {
		let clampedUrgency = max(0, min(1, urgency))
		guard clampedUrgency > 0.35 else { return }

		let pulse = 0.5 + (0.5 * sin(elapsed * (6 + (clampedUrgency * 10))))
		let opacity = (clampedUrgency - 0.30) * 0.20 * pulse
		let tintRect = CGRect(origin: .zero, size: size)
		context.fill(
			Path(tintRect),
			with: .color(Color(red: 0.45, green: 0.03, blue: 0.03).opacity(opacity))
		)
	}

	fileprivate func drawDecisionBeacons(
		into context: inout GraphicsContext,
		frame: CaveTunnelFrame,
		size: CGSize,
		elapsed: TimeInterval
	) {
		let choiceCount = decisionChoiceCount
		let remainingRatio = decisionRemainingRatio ?? 1
		let spacing = min(size.width * 0.18, 150)
		let baseY = frame.horizonY + (size.height * 0.11) + (frame.cameraOffset.height * 0.25)
		let baseX = (size.width * 0.5) + (frame.cameraOffset.width * 0.30)
		let urgency = 1 - max(0, min(1, remainingRatio))
		let pulse = 0.75 + (0.25 * sin(elapsed * 9)) + (urgency * 0.45)

		for index in 0..<choiceCount {
			let normalizedOffset = CGFloat(index) - (CGFloat(choiceCount - 1) * 0.5)
			let center = CGPoint(
				x: baseX + (normalizedOffset * spacing),
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

	fileprivate func drawGameOverMask(into context: inout GraphicsContext, size: CGSize) {
		context.fill(
			Path(CGRect(origin: .zero, size: size)),
			with: .color(.black.opacity(0.35))
		)
	}
}

extension CaveRunSceneView {
	fileprivate func quadPath(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Path {
		var path = Path()
		path.move(to: p1)
		path.addLine(to: p2)
		path.addLine(to: p3)
		path.addLine(to: p4)
		path.closeSubpath()
		return path
	}

	fileprivate func normalizedPerpendicular(from start: CGPoint, to end: CGPoint) -> CGPoint {
		let vectorX = end.x - start.x
		let vectorY = end.y - start.y
		let length = max(0.001, sqrt((vectorX * vectorX) + (vectorY * vectorY)))
		return CGPoint(x: -vectorY / length, y: vectorX / length)
	}

	fileprivate func buildBatPath(
		center: CGPoint,
		wingSpread: CGFloat,
		wingLift: CGFloat,
		bodyHeight: CGFloat
	) -> Path {
		var path = Path()
		let leftWing = CGPoint(x: center.x - wingSpread, y: center.y - wingLift)
		let rightWing = CGPoint(x: center.x + wingSpread, y: center.y - wingLift)
		let bodyBottom = CGPoint(x: center.x, y: center.y + bodyHeight)

		path.move(to: leftWing)
		path.addQuadCurve(to: bodyBottom, control: CGPoint(x: center.x - (wingSpread * 0.35), y: center.y))
		path.addQuadCurve(to: rightWing, control: CGPoint(x: center.x + (wingSpread * 0.35), y: center.y))
		path.addLine(to: CGPoint(x: center.x, y: center.y - (bodyHeight * 0.35)))
		path.closeSubpath()

		return path
	}

	fileprivate func mix(_ from: CGPoint, _ to: CGPoint, amount: CGFloat) -> CGPoint {
		let clampedAmount = max(0, min(1, amount))
		return CGPoint(
			x: from.x + ((to.x - from.x) * clampedAmount),
			y: from.y + ((to.y - from.y) * clampedAmount)
		)
	}
}
