import AVFoundation
import XCTest
@testable import FinalRoundLite

final class AudioPCM16BufferConverterTests: XCTestCase {
    func testConvertToPCM16Mono_convertsFloatMonoWithoutResampling() throws {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        )
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: try XCTUnwrap(format), frameCapacity: 4))
        buffer.frameLength = 4
        let channel = try XCTUnwrap(buffer.floatChannelData?.pointee)
        channel[0] = -1
        channel[1] = -0.5
        channel[2] = 0
        channel[3] = 0.5

        let data = try XCTUnwrap(
            AudioPCM16BufferConverter.convertToPCM16Mono(buffer: buffer, targetSampleRate: 16_000)
        )
        XCTAssertEqual(data.count, 8)

        let values = decodePCM16(data)
        XCTAssertEqual(values.count, 4)
        XCTAssertEqual(values[0], Int16.min + 1, accuracy: 2)
        XCTAssertEqual(values[1], -16_383, accuracy: 2)
        XCTAssertEqual(values[2], 0, accuracy: 1)
        XCTAssertEqual(values[3], 16_383, accuracy: 2)
    }

    func testConvertToPCM16Mono_downmixesStereoFloatToMono() throws {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 2,
            interleaved: false
        )
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: try XCTUnwrap(format), frameCapacity: 2))
        buffer.frameLength = 2
        let channels = try XCTUnwrap(buffer.floatChannelData)
        channels[0][0] = 1
        channels[1][0] = -1
        channels[0][1] = 0.5
        channels[1][1] = -0.5

        let data = try XCTUnwrap(
            AudioPCM16BufferConverter.convertToPCM16Mono(buffer: buffer, targetSampleRate: 16_000)
        )
        let values = decodePCM16(data)
        XCTAssertEqual(values, [0, 0])
    }

    func testConvertToPCM16Mono_resamplesToTargetSampleRate() throws {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48_000,
            channels: 1,
            interleaved: false
        )
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: try XCTUnwrap(format), frameCapacity: 48))
        buffer.frameLength = 48
        let channel = try XCTUnwrap(buffer.floatChannelData?.pointee)
        for index in 0..<48 {
            channel[index] = 0.25
        }

        let data = try XCTUnwrap(
            AudioPCM16BufferConverter.convertToPCM16Mono(buffer: buffer, targetSampleRate: 16_000)
        )
        let values = decodePCM16(data)
        XCTAssertEqual(values.count, 16)
        let firstSample = try XCTUnwrap(values.first)
        XCTAssertEqual(Double(firstSample), 8_191, accuracy: 3)
    }

    func testConvertToPCM16Mono_returnsNilForUnsupportedFormat() throws {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatInt32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        )
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: try XCTUnwrap(format), frameCapacity: 4))
        buffer.frameLength = 4

        let result = AudioPCM16BufferConverter.convertToPCM16Mono(buffer: buffer, targetSampleRate: 16_000)
        XCTAssertNil(result)
    }

    private func decodePCM16(_ data: Data) -> [Int16] {
        data.withUnsafeBytes { raw in
            guard let base = raw.bindMemory(to: Int16.self).baseAddress else { return [] }
            let count = data.count / MemoryLayout<Int16>.size
            return Array(UnsafeBufferPointer(start: base, count: count))
        }
    }
}
