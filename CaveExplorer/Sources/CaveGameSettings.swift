import CaveDomain
import Foundation

struct CaveGameSettings: Equatable {
	static let depthRange = 3...15
	static let decisionTimeRange: ClosedRange<Double> = 3...10
	static let happyEndingStartPercentRange: ClosedRange<Double> = 0.6...0.9
	static let `default` = CaveGameSettings()

	var maxDepth: Int
	var decisionTime: Double
	var happyEndingStartPercent: Double

	init(
		maxDepth: Int = 5,
		decisionTime: Double = 5.0,
		happyEndingStartPercent: Double = 0.8
	) {
		self.maxDepth = maxDepth
		self.decisionTime = decisionTime
		self.happyEndingStartPercent = happyEndingStartPercent
	}

	var normalized: CaveGameSettings {
		CaveGameSettings(
			maxDepth: clamp(maxDepth, minValue: Self.depthRange.lowerBound, maxValue: Self.depthRange.upperBound),
			decisionTime: clamp(
				decisionTime, minValue: Self.decisionTimeRange.lowerBound, maxValue: Self.decisionTimeRange.upperBound),
			happyEndingStartPercent: clamp(
				happyEndingStartPercent,
				minValue: Self.happyEndingStartPercentRange.lowerBound,
				maxValue: Self.happyEndingStartPercentRange.upperBound
			)
		)
	}

	var caveConfig: CaveConfig {
		let normalized = normalized
		return CaveConfig(
			maxDepth: normalized.maxDepth,
			decisionTime: normalized.decisionTime,
			happyEndingStartPercent: normalized.happyEndingStartPercent
		)
	}
}

private func clamp<T: Comparable>(_ value: T, minValue: T, maxValue: T) -> T {
	min(maxValue, max(minValue, value))
}
