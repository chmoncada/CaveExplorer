import CoreGraphics
import XCTest

@testable import CaveExplorer

final class CaveAtmosphereFrameBuilderTests: XCTestCase {
	func test_makeFrame_respectsConfiguredCounts() {
		let builder = CaveAtmosphereFrameBuilder(fogBandCount: 5, dustCount: 24, batCount: 4)

		let frame = builder.makeFrame(
			in: CGSize(width: 960, height: 640),
			elapsed: 1.1,
			travelProgress: 0.5,
			torchPulse: 0.4,
			urgency: 0.2
		)

		XCTAssertEqual(frame.fogBands.count, 5)
		XCTAssertEqual(frame.dustParticles.count, 24)
		XCTAssertEqual(frame.bats.count, 4)
	}

	func test_makeFrame_clampsUrgencyAndPulse() {
		let builder = CaveAtmosphereFrameBuilder(fogBandCount: 3, dustCount: 10, batCount: 2)
		let size = CGSize(width: 900, height: 600)

		let low = builder.makeFrame(
			in: size,
			elapsed: 0.6,
			travelProgress: 0.3,
			torchPulse: -3,
			urgency: -2
		)
		let high = builder.makeFrame(
			in: size,
			elapsed: 0.6,
			travelProgress: 0.3,
			torchPulse: 5,
			urgency: 9
		)

		XCTAssertGreaterThanOrEqual(high.fogBands[0].opacity, low.fogBands[0].opacity)

		let lowAverageDustRadius = low.dustParticles.map(\.radius).reduce(0, +) / CGFloat(low.dustParticles.count)
		let highAverageDustRadius = high.dustParticles.map(\.radius).reduce(0, +) / CGFloat(high.dustParticles.count)
		XCTAssertGreaterThan(highAverageDustRadius, lowAverageDustRadius)
	}

	func test_makeFrame_movesContentOverTime() {
		let builder = CaveAtmosphereFrameBuilder(fogBandCount: 4, dustCount: 16, batCount: 3)
		let size = CGSize(width: 1000, height: 700)

		let frameA = builder.makeFrame(
			in: size,
			elapsed: 0.0,
			travelProgress: 0.2,
			torchPulse: 0.5,
			urgency: 0.0
		)
		let frameB = builder.makeFrame(
			in: size,
			elapsed: 1.0,
			travelProgress: 0.2,
			torchPulse: 0.5,
			urgency: 0.0
		)

		XCTAssertNotEqual(frameA.fogBands[0].rect.minX, frameB.fogBands[0].rect.minX, accuracy: 0.001)
		XCTAssertNotEqual(frameA.dustParticles[0].center.x, frameB.dustParticles[0].center.x, accuracy: 0.001)
		XCTAssertNotEqual(frameA.bats[0].center.x, frameB.bats[0].center.x, accuracy: 0.001)
	}

	func test_makeFrame_zeroSizedCanvas_returnsEmptyFrame() {
		let builder = CaveAtmosphereFrameBuilder()

		let frame = builder.makeFrame(
			in: .zero,
			elapsed: 1.0,
			travelProgress: 0.4,
			torchPulse: 0.7,
			urgency: 0.8
		)

		XCTAssertTrue(frame.fogBands.isEmpty)
		XCTAssertTrue(frame.dustParticles.isEmpty)
		XCTAssertTrue(frame.bats.isEmpty)
	}
}
