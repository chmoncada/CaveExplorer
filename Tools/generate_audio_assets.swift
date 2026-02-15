import Foundation

private let sampleRate = 44_100.0
private let twoPi = Double.pi * 2

private struct AudioFile {
	let fileName: String
	let samples: [Double]
}

private extension Data {
	mutating func appendUInt16LE(_ value: UInt16) {
		append(UInt8(value & 0xff))
		append(UInt8((value >> 8) & 0xff))
	}

	mutating func appendUInt32LE(_ value: UInt32) {
		append(UInt8(value & 0xff))
		append(UInt8((value >> 8) & 0xff))
		append(UInt8((value >> 16) & 0xff))
		append(UInt8((value >> 24) & 0xff))
	}
}

private func clamp(_ value: Double, min minValue: Double = -1, max maxValue: Double = 1) -> Double {
	Swift.max(minValue, Swift.min(maxValue, value))
}

private func envelope(_ t: Double, duration: Double, attack: Double, release: Double) -> Double {
	guard duration > 0 else { return 0 }
	let a = Swift.max(0.0001, attack)
	let r = Swift.max(0.0001, release)

	if t < a {
		return t / a
	}

	if t > duration - r {
		return Swift.max(0, (duration - t) / r)
	}

	return 1
}

private func tone(
	frequency: Double,
	duration: Double,
	gain: Double,
	attack: Double = 0.01,
	release: Double = 0.06,
	vibratoRate: Double = 0,
	vibratoDepth: Double = 0
) -> [Double] {
	let count = Swift.max(0, Int(duration * sampleRate))
	guard count > 0 else { return [] }

	return (0..<count).map { index in
		let t = Double(index) / sampleRate
		let vibrato = vibratoDepth > 0 ? sin(twoPi * vibratoRate * t) * vibratoDepth : 0
		let freq = frequency * (1 + vibrato)
		let wave = sin(twoPi * freq * t)
		let amp = envelope(t, duration: duration, attack: attack, release: release)
		return wave * gain * amp
	}
}

private func silence(duration: Double) -> [Double] {
	let count = Swift.max(0, Int(duration * sampleRate))
	guard count > 0 else { return [] }
	return Array(repeating: 0, count: count)
}

private func concatenate(_ segments: [[Double]]) -> [Double] {
	segments.flatMap { $0 }
}

private func mix(_ layers: [[Double]]) -> [Double] {
	let maxLength = layers.map(\.count).max() ?? 0
	guard maxLength > 0 else { return [] }

	var mixed = Array(repeating: 0.0, count: maxLength)
	for layer in layers {
		for (index, sample) in layer.enumerated() {
			mixed[index] += sample
		}
	}
	return normalizeIfNeeded(mixed)
}

private func normalizeIfNeeded(_ samples: [Double]) -> [Double] {
	guard let peak = samples.map({ abs($0) }).max(), peak > 0.97 else {
		return samples.map { clamp($0) }
	}
	let scale = 0.97 / peak
	return samples.map { clamp($0 * scale) }
}

private func fadeInOut(_ samples: [Double], fadeDuration: Double) -> [Double] {
	guard !samples.isEmpty else { return [] }
	let fadeSamples = Int(fadeDuration * sampleRate)
	guard fadeSamples > 0 else { return samples }

	var output = samples
	let lastIndex = output.count - 1
	for index in 0..<Swift.min(fadeSamples, output.count) {
		let ratio = Double(index) / Double(fadeSamples)
		output[index] *= ratio
		output[lastIndex - index] *= ratio
	}
	return output
}

private func makeBackgroundLoop(duration: Double) -> [Double] {
	let count = Swift.max(0, Int(duration * sampleRate))
	guard count > 0 else { return [] }

	let samples = (0..<count).map { index in
		let t = Double(index) / sampleRate

		let droneBase = sin(twoPi * 55 * t)
		let droneHarmonic = sin(twoPi * 82 * t + (sin(twoPi * 0.11 * t) * 0.65))
		let droneWhine = sin(twoPi * 110 * t)

		let pulse = pow((sin(twoPi * 1.7 * t) + 1) * 0.5, 2.2)
		let phase = t.truncatingRemainder(dividingBy: 1.55)
		let heartbeat = phase < 0.09 ? sin(twoPi * 80 * phase) * exp(-phase * 22) : 0
		let hiss = sin(twoPi * 2_600 * t) * sin(twoPi * 0.23 * t) * 0.03

		let combined = (droneBase * 0.35) + (droneHarmonic * 0.2) + (droneWhine * 0.08)
		return (combined * (0.65 + (0.25 * pulse))) + (heartbeat * 0.35) + hiss
	}

	return normalizeIfNeeded(fadeInOut(samples, fadeDuration: 0.08)).map { $0 * 0.78 }
}

private func writeWav(samples: [Double], to url: URL) throws {
	let intSamples = samples.map { value -> Int16 in
		Int16(clamp(value) * Double(Int16.max))
	}
	let channels: UInt16 = 1
	let bitsPerSample: UInt16 = 16
	let byteRate = UInt32(sampleRate) * UInt32(channels) * UInt32(bitsPerSample / 8)
	let blockAlign = channels * (bitsPerSample / 8)
	let dataSize = UInt32(intSamples.count * Int(blockAlign))
	let fileSize = 36 + dataSize

	var data = Data()
	data.append("RIFF".data(using: .ascii)!)
	data.appendUInt32LE(fileSize)
	data.append("WAVE".data(using: .ascii)!)

	data.append("fmt ".data(using: .ascii)!)
	data.appendUInt32LE(16)
	data.appendUInt16LE(1)
	data.appendUInt16LE(channels)
	data.appendUInt32LE(UInt32(sampleRate))
	data.appendUInt32LE(byteRate)
	data.appendUInt16LE(blockAlign)
	data.appendUInt16LE(bitsPerSample)

	data.append("data".data(using: .ascii)!)
	data.appendUInt32LE(dataSize)

	for sample in intSamples {
		let value = UInt16(bitPattern: sample)
		data.appendUInt16LE(value)
	}

	try data.write(to: url, options: .atomic)
}

private func makeSoundFiles() -> [AudioFile] {
	let runStarted = concatenate([
		tone(frequency: 420, duration: 0.08, gain: 0.55, release: 0.03),
		tone(frequency: 670, duration: 0.12, gain: 0.6, attack: 0.005, release: 0.07, vibratoRate: 8, vibratoDepth: 0.02)
	])

	let decisionAppeared = mix([
		tone(frequency: 720, duration: 0.09, gain: 0.58, release: 0.07),
		tone(frequency: 1_050, duration: 0.05, gain: 0.25, attack: 0.001, release: 0.03)
	])

	let decisionUrgent = concatenate([
		tone(frequency: 860, duration: 0.1, gain: 0.75, release: 0.05),
		silence(duration: 0.06),
		tone(frequency: 940, duration: 0.1, gain: 0.78, release: 0.05),
		silence(duration: 0.06),
		tone(frequency: 1_020, duration: 0.12, gain: 0.82, release: 0.07)
	])

	let pathSelected = mix([
		tone(frequency: 520, duration: 0.06, gain: 0.45, release: 0.03),
		tone(frequency: 1_180, duration: 0.03, gain: 0.3, attack: 0.001, release: 0.02)
	])

	let failureEnding = concatenate([
		tone(frequency: 320, duration: 0.16, gain: 0.6, release: 0.08),
		tone(frequency: 240, duration: 0.2, gain: 0.58, release: 0.1),
		tone(frequency: 170, duration: 0.28, gain: 0.55, release: 0.14)
	])

	let happyEnding = concatenate([
		tone(frequency: 440, duration: 0.11, gain: 0.6, release: 0.05),
		tone(frequency: 554, duration: 0.11, gain: 0.62, release: 0.05),
		tone(frequency: 659, duration: 0.16, gain: 0.64, release: 0.06),
		tone(frequency: 880, duration: 0.3, gain: 0.68, release: 0.16, vibratoRate: 5, vibratoDepth: 0.01)
	])

	let bgLoop = makeBackgroundLoop(duration: 14.0)

	return [
		AudioFile(fileName: "run_started", samples: runStarted),
		AudioFile(fileName: "decision_appeared", samples: decisionAppeared),
		AudioFile(fileName: "decision_urgent", samples: decisionUrgent),
		AudioFile(fileName: "path_selected", samples: pathSelected),
		AudioFile(fileName: "failure_ending", samples: failureEnding),
		AudioFile(fileName: "happy_ending", samples: happyEnding),
		AudioFile(fileName: "bg_chase_loop", samples: bgLoop)
	]
}

let outputDirectoryPath: String
if CommandLine.arguments.count > 1 {
	outputDirectoryPath = CommandLine.arguments[1]
} else {
	outputDirectoryPath = "CaveExplorer/Resources/Audio"
}

let fileManager = FileManager.default
let outputDirectoryURL = URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)

try fileManager.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true)

for file in makeSoundFiles() {
	let url = outputDirectoryURL.appendingPathComponent(file.fileName).appendingPathExtension("wav")
	try writeWav(samples: file.samples, to: url)
	print("Generated \(url.path)")
}
