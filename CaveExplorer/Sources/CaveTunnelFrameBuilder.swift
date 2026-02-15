import CoreGraphics
import Foundation

struct CaveTunnelLayer {
	let outerRect: CGRect
	let innerRect: CGRect
	let intensity: Double
}

struct CaveTunnelFrame {
	let layers: [CaveTunnelLayer]
	let torchRadius: CGFloat
	let horizonY: CGFloat
}

struct CaveTunnelFrameBuilder {
	let segmentCount: Int

	init(segmentCount: Int = 9) {
		precondition(segmentCount >= 2, "segmentCount must be >= 2")
		self.segmentCount = segmentCount
	}

	func makeFrame(
		in size: CGSize,
		elapsed: TimeInterval,
		travelProgress: Double,
		pulse: Double
	) -> CaveTunnelFrame {
		guard size.width > 0, size.height > 0 else {
			return CaveTunnelFrame(layers: [], torchRadius: 0, horizonY: 0)
		}

		let motion = (elapsed * 0.55) + (travelProgress * 1.8)
		let sway = sin(elapsed * 2.4) * 0.012
		let nod = sin(elapsed * 1.9) * 0.010

		let centerX = size.width * (0.5 + CGFloat(sway))
		let centerY = size.height * (0.54 + CGFloat(nod))
		let minHalfWidth = size.width * 0.05
		let maxHalfWidth = size.width * 0.52
		let minHalfHeight = size.height * 0.06
		let maxHalfHeight = size.height * 0.46

		var layers: [CaveTunnelLayer] = []
		layers.reserveCapacity(segmentCount)

		for index in 0..<segmentCount {
			let normalizedIndex = Double(index) / Double(segmentCount)
			let depth = fractionalPart(of: normalizedIndex + motion)
			let perspective = pow(depth, 0.78)

			let halfWidth = lerp(minHalfWidth, maxHalfWidth, CGFloat(perspective))
			let halfHeight = lerp(minHalfHeight, maxHalfHeight, CGFloat(perspective))

			let outerRect = CGRect(
				x: centerX - halfWidth,
				y: centerY - halfHeight,
				width: halfWidth * 2,
				height: halfHeight * 2
			)

			let innerHalfWidth = halfWidth * 0.66
			let innerHalfHeight = halfHeight * 0.63
			let innerRect = CGRect(
				x: centerX - innerHalfWidth,
				y: centerY - innerHalfHeight,
				width: innerHalfWidth * 2,
				height: innerHalfHeight * 2
			)

			layers.append(
				CaveTunnelLayer(
					outerRect: outerRect,
					innerRect: innerRect,
					intensity: 1 - depth
				)
			)
		}

		let sortedLayers = layers.sorted { $0.outerRect.width < $1.outerRect.width }
		let clampedPulse = clamp(pulse, minValue: 0, maxValue: 1)
		let torchRadius = lerp(size.height * 0.24, size.height * 0.36, CGFloat(clampedPulse))
		let horizonY = centerY - (size.height * 0.08)

		return CaveTunnelFrame(layers: sortedLayers, torchRadius: torchRadius, horizonY: horizonY)
	}
}

private func clamp(_ value: Double, minValue: Double, maxValue: Double) -> Double {
	min(maxValue, max(minValue, value))
}

private func lerp(_ from: CGFloat, _ to: CGFloat, _ amount: CGFloat) -> CGFloat {
	from + ((to - from) * amount)
}

private func fractionalPart(of value: Double) -> Double {
	value - floor(value)
}
