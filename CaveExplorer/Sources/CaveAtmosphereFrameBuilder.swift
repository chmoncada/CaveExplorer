import CoreGraphics
import Foundation

struct CaveFogBand {
	let rect: CGRect
	let opacity: Double
}

struct CaveDustParticle {
	let center: CGPoint
	let radius: CGFloat
	let opacity: Double
}

struct CaveBatSprite {
	let center: CGPoint
	let scale: CGFloat
	let flapPhase: Double
	let opacity: Double
}

struct CaveAtmosphereFrame {
	let fogBands: [CaveFogBand]
	let dustParticles: [CaveDustParticle]
	let bats: [CaveBatSprite]
}

struct CaveAtmosphereFrameBuilder {
	let fogBandCount: Int
	let dustCount: Int
	let batCount: Int

	init(fogBandCount: Int = 4, dustCount: Int = 32, batCount: Int = 3) {
		precondition(fogBandCount >= 1, "fogBandCount must be >= 1")
		precondition(dustCount >= 0, "dustCount must be >= 0")
		precondition(batCount >= 0, "batCount must be >= 0")

		self.fogBandCount = fogBandCount
		self.dustCount = dustCount
		self.batCount = batCount
	}

	func makeFrame(
		in size: CGSize,
		elapsed: TimeInterval,
		travelProgress: Double,
		torchPulse: Double,
		urgency: Double
	) -> CaveAtmosphereFrame {
		guard size.width > 0, size.height > 0 else {
			return CaveAtmosphereFrame(fogBands: [], dustParticles: [], bats: [])
		}

		let clampedUrgency = clamp(urgency, minValue: 0, maxValue: 1)
		let clampedPulse = clamp(torchPulse, minValue: 0, maxValue: 1)

		let fogBands = buildFogBands(
			in: size,
			elapsed: elapsed,
			urgency: clampedUrgency
		)
		let dustParticles = buildDustParticles(
			in: size,
			elapsed: elapsed,
			travelProgress: travelProgress,
			torchPulse: clampedPulse
		)
		let bats = buildBats(
			in: size,
			elapsed: elapsed,
			urgency: clampedUrgency
		)

		return CaveAtmosphereFrame(
			fogBands: fogBands,
			dustParticles: dustParticles,
			bats: bats
		)
	}

	private func buildFogBands(
		in size: CGSize,
		elapsed: TimeInterval,
		urgency: Double
	) -> [CaveFogBand] {
		var fogBands: [CaveFogBand] = []
		fogBands.reserveCapacity(fogBandCount)

		for index in 0..<fogBandCount {
			let indexRatio = CGFloat(index) / CGFloat(max(1, fogBandCount - 1))
			let bandHeight = size.height * (0.10 + (0.06 * indexRatio))
			let drift = CGFloat(sin((elapsed * 0.14) + Double(index))) * (size.width * 0.04)
			let y = size.height * (0.26 + (0.16 * indexRatio))

			let rect = CGRect(
				x: (-size.width * 0.1) + drift,
				y: y,
				width: size.width * 1.2,
				height: bandHeight
			)
			let opacity = 0.05 + (0.05 * Double(indexRatio)) + (0.05 * urgency)

			fogBands.append(CaveFogBand(rect: rect, opacity: opacity))
		}

		return fogBands
	}

	private func buildDustParticles(
		in size: CGSize,
		elapsed: TimeInterval,
		travelProgress: Double,
		torchPulse: Double
	) -> [CaveDustParticle] {
		var dustParticles: [CaveDustParticle] = []
		dustParticles.reserveCapacity(dustCount)

		for index in 0..<dustCount {
			let seed = Double(index) * 13.731
			let xPhase = fractionalPart(of: hash(seed * 1.37) + (elapsed * 0.025) + (travelProgress * 0.06))
			let yPhase = fractionalPart(of: hash(seed * 2.91) + (elapsed * 0.052))
			let depth = fractionalPart(of: hash(seed * 5.41) + (elapsed * 0.031))

			let center = CGPoint(
				x: size.width * CGFloat(xPhase),
				y: size.height * CGFloat(yPhase)
			)
			let radius = (1.0 + (2.6 * CGFloat(depth))) * (0.8 + (0.4 * CGFloat(torchPulse)))
			let opacity = 0.08 + (0.18 * (1 - depth)) + (0.08 * torchPulse)

			dustParticles.append(CaveDustParticle(center: center, radius: radius, opacity: opacity))
		}

		return dustParticles
	}

	private func buildBats(
		in size: CGSize,
		elapsed: TimeInterval,
		urgency: Double
	) -> [CaveBatSprite] {
		var bats: [CaveBatSprite] = []
		bats.reserveCapacity(batCount)

		for index in 0..<batCount {
			let seed = Double(index) * 19.117
			let horizontal = fractionalPart(of: hash(seed * 0.71) + (elapsed * (0.05 + (0.011 * Double(index)))))
			let vertical = fractionalPart(of: hash(seed * 1.93) + (elapsed * 0.022))
			let flapPhase = (elapsed * (8.0 + Double(index))) + (seed * 0.4)

			let center = CGPoint(
				x: size.width * CGFloat(0.15 + (0.70 * horizontal)),
				y: size.height * CGFloat(0.14 + (0.30 * vertical))
			)
			let scale = 0.55 + (0.35 * CGFloat(fractionalPart(of: hash(seed * 4.12)))) + (0.25 * CGFloat(urgency))
			let opacity = 0.20 + (0.22 * urgency)

			bats.append(CaveBatSprite(center: center, scale: scale, flapPhase: flapPhase, opacity: opacity))
		}

		return bats
	}
}

private func hash(_ value: Double) -> Double {
	sin(value * 12.9898) * 43758.5453
}

private func clamp(_ value: Double, minValue: Double, maxValue: Double) -> Double {
	min(maxValue, max(minValue, value))
}

private func fractionalPart(of value: Double) -> Double {
	value - floor(value)
}
