import CoreGraphics
import XCTest

@testable import CaveExplorer

final class CaveTunnelFrameBuilderTests: XCTestCase {
	func test_makeFrame_createsExpectedSegmentCount() {
		let builder = CaveTunnelFrameBuilder(segmentCount: 12)

		let frame = builder.makeFrame(
			in: CGSize(width: 900, height: 640),
			elapsed: 1.2,
			travelProgress: 0.3,
			pulse: 0.5
		)

		XCTAssertEqual(frame.layers.count, 12)
	}

	func test_makeFrame_sortsLayersFromFarToNear() {
		let builder = CaveTunnelFrameBuilder(segmentCount: 10)

		let frame = builder.makeFrame(
			in: CGSize(width: 900, height: 640),
			elapsed: 2.5,
			travelProgress: 0.4,
			pulse: 0.2
		)

		for index in 1..<frame.layers.count {
			let previous = frame.layers[index - 1].outerRect.width
			let current = frame.layers[index].outerRect.width
			XCTAssertGreaterThanOrEqual(current, previous)
		}
	}

	func test_makeFrame_torchRadius_increasesWithPulse() {
		let builder = CaveTunnelFrameBuilder(segmentCount: 8)
		let size = CGSize(width: 960, height: 640)

		let lowPulse = builder.makeFrame(
			in: size,
			elapsed: 0.8,
			travelProgress: 0.1,
			pulse: 0
		)
		let highPulse = builder.makeFrame(
			in: size,
			elapsed: 0.8,
			travelProgress: 0.1,
			pulse: 1
		)

		XCTAssertGreaterThan(highPulse.torchRadius, lowPulse.torchRadius)
	}

	func test_makeFrame_changesWhenElapsedTimeChanges() {
		let builder = CaveTunnelFrameBuilder(segmentCount: 9)
		let size = CGSize(width: 900, height: 640)

		let frameA = builder.makeFrame(
			in: size,
			elapsed: 0.0,
			travelProgress: 0.3,
			pulse: 0.5
		)
		let frameB = builder.makeFrame(
			in: size,
			elapsed: 0.42,
			travelProgress: 0.3,
			pulse: 0.5
		)

		XCTAssertFalse(frameA.layers.isEmpty)
		XCTAssertFalse(frameB.layers.isEmpty)

		let firstWidthA = frameA.layers[0].outerRect.width
		let firstWidthB = frameB.layers[0].outerRect.width
		XCTAssertNotEqual(firstWidthA, firstWidthB, accuracy: 0.001)
	}

	func test_makeFrame_exposesDynamicCameraOffset() {
		let builder = CaveTunnelFrameBuilder(segmentCount: 10)
		let size = CGSize(width: 900, height: 640)

		let frameA = builder.makeFrame(
			in: size,
			elapsed: 0.1,
			travelProgress: 0.2,
			pulse: 0.5
		)
		let frameB = builder.makeFrame(
			in: size,
			elapsed: 0.8,
			travelProgress: 0.2,
			pulse: 0.5
		)

		XCTAssertNotEqual(frameA.cameraOffset.width, frameB.cameraOffset.width, accuracy: 0.001)
		XCTAssertNotEqual(frameA.cameraOffset.height, frameB.cameraOffset.height, accuracy: 0.001)
	}

	func test_makeFrame_placesTorchAnchorInsideViewport() {
		let builder = CaveTunnelFrameBuilder(segmentCount: 10)
		let size = CGSize(width: 900, height: 640)

		let frame = builder.makeFrame(
			in: size,
			elapsed: 1.0,
			travelProgress: 0.5,
			pulse: 0.7
		)

		XCTAssertGreaterThanOrEqual(frame.torchAnchor.x, 0)
		XCTAssertLessThanOrEqual(frame.torchAnchor.x, size.width)
		XCTAssertGreaterThanOrEqual(frame.torchAnchor.y, 0)
		XCTAssertLessThanOrEqual(frame.torchAnchor.y, size.height)
	}

	func test_makeFrame_urgencyIncreasesCameraDisplacement() {
		let builder = CaveTunnelFrameBuilder(segmentCount: 10)
		let size = CGSize(width: 900, height: 640)

		let lowUrgency = builder.makeFrame(
			in: size,
			elapsed: 0.37,
			travelProgress: 0.42,
			depthProgress: 0.4,
			urgency: 0.0,
			pulse: 0.5
		)
		let highUrgency = builder.makeFrame(
			in: size,
			elapsed: 0.37,
			travelProgress: 0.42,
			depthProgress: 0.4,
			urgency: 1.0,
			pulse: 0.5
		)

		XCTAssertGreaterThan(displacement(of: highUrgency), displacement(of: lowUrgency))
	}

	func test_makeFrame_depthProgressIncreasesCameraDisplacement() {
		let builder = CaveTunnelFrameBuilder(segmentCount: 10)
		let size = CGSize(width: 900, height: 640)

		let shallow = builder.makeFrame(
			in: size,
			elapsed: 0.37,
			travelProgress: 0.42,
			depthProgress: 0.0,
			urgency: 0.25,
			pulse: 0.5
		)
		let deep = builder.makeFrame(
			in: size,
			elapsed: 0.37,
			travelProgress: 0.42,
			depthProgress: 1.0,
			urgency: 0.25,
			pulse: 0.5
		)

		XCTAssertGreaterThan(displacement(of: deep), displacement(of: shallow))
	}

	private func displacement(of frame: CaveTunnelFrame) -> CGFloat {
		sqrt(
			(frame.cameraOffset.width * frame.cameraOffset.width) + (frame.cameraOffset.height * frame.cameraOffset.height))
	}
}
