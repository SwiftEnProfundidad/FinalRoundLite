import AVFoundation
import Foundation

struct AudioChunk: Sendable {
    let id: UUID
    let pcm16Data: Data
    let sampleRate: Int
    let channels: Int
    let durationSeconds: Double
    let voiceRatio: Double
}

final class AudioCaptureService {
    enum CaptureError: Error {
        case missingInputFormat
        case failedToStartEngine
    }

    private let engine = AVAudioEngine()
    private var continuation: AsyncStream<AudioChunk>.Continuation?
    private var isRunning = false

    private let targetSampleRate: Double = 16_000
    private let chunkDurationSeconds: Double = 5.0

    private var pcm16Buffer = Data()
    private var voiceFrameCount: Int = 0
    private var totalFrameCount: Int = 0

    @MainActor
    func start() throws -> AsyncStream<AudioChunk> {
        guard !isRunning else {
            return AsyncStream { _ in }
        }
        isRunning = true

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        guard inputFormat.channelCount > 0 else { throw CaptureError.missingInputFormat }

        let stream = AsyncStream<AudioChunk> { cont in
            self.continuation = cont
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.handleIncomingBuffer(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            stop()
            throw CaptureError.failedToStartEngine
        }

        return stream
    }

    @MainActor
    func stop() {
        guard isRunning else { return }
        isRunning = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        pcm16Buffer.removeAll(keepingCapacity: true)
        voiceFrameCount = 0
        totalFrameCount = 0
        continuation?.finish()
        continuation = nil
    }

    private func handleIncomingBuffer(_ buffer: AVAudioPCMBuffer) {
        let voice = AudioVAD.isVoice(buffer)
        totalFrameCount += Int(buffer.frameLength)
        if voice { voiceFrameCount += Int(buffer.frameLength) }

        guard let convertedPCM16 = AudioPCM16BufferConverter.convertToPCM16Mono(
            buffer: buffer,
            targetSampleRate: targetSampleRate
        ) else { return }
        pcm16Buffer.append(convertedPCM16)

        let framesPerChunk = Int(targetSampleRate * chunkDurationSeconds)
        let bytesPerFrame = 2
        let requiredBytes = framesPerChunk * bytesPerFrame

        if pcm16Buffer.count >= requiredBytes {
            let chunkData = pcm16Buffer.prefix(requiredBytes)
            pcm16Buffer.removeFirst(requiredBytes)

            let voiceRatio = totalFrameCount == 0 ? 0 : Double(voiceFrameCount) / Double(totalFrameCount)
            voiceFrameCount = 0
            totalFrameCount = 0

            guard voiceRatio >= 0.08 else { return }

            let chunk = AudioChunk(
                id: UUID(),
                pcm16Data: Data(chunkData),
                sampleRate: Int(targetSampleRate),
                channels: 1,
                durationSeconds: chunkDurationSeconds,
                voiceRatio: voiceRatio
            )
            continuation?.yield(chunk)
        }
    }
}

enum AudioPCM16BufferConverter {
    static func convertToPCM16Mono(buffer: AVAudioPCMBuffer, targetSampleRate: Double) -> Data? {
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return Data() }

        let monoSamples: [Float]
        switch buffer.format.commonFormat {
        case .pcmFormatFloat32:
            guard let channels = buffer.floatChannelData else { return nil }
            monoSamples = downmixFloatToMono(
                channels: channels,
                channelCount: Int(buffer.format.channelCount),
                frameCount: frameCount
            )
        case .pcmFormatInt16:
            guard let channels = buffer.int16ChannelData else { return nil }
            monoSamples = downmixInt16ToMono(
                channels: channels,
                channelCount: Int(buffer.format.channelCount),
                frameCount: frameCount
            )
        default:
            return nil
        }

        let resampled = resampleLinear(
            monoSamples,
            sourceSampleRate: buffer.format.sampleRate,
            targetSampleRate: targetSampleRate
        )
        return encodePCM16(samples: resampled)
    }

    private static func downmixFloatToMono(
        channels: UnsafePointer<UnsafeMutablePointer<Float>>,
        channelCount: Int,
        frameCount: Int
    ) -> [Float] {
        guard channelCount > 1 else {
            let channel = channels[0]
            return Array(UnsafeBufferPointer(start: channel, count: frameCount))
        }
        var mono = Array(repeating: Float.zero, count: frameCount)
        for frame in 0..<frameCount {
            var sum: Float = 0
            for channelIndex in 0..<channelCount {
                sum += channels[channelIndex][frame]
            }
            mono[frame] = sum / Float(channelCount)
        }
        return mono
    }

    private static func downmixInt16ToMono(
        channels: UnsafePointer<UnsafeMutablePointer<Int16>>,
        channelCount: Int,
        frameCount: Int
    ) -> [Float] {
        var mono = Array(repeating: Float.zero, count: frameCount)
        let scale = Float(Int16.max)

        for frame in 0..<frameCount {
            var sum: Float = 0
            for channelIndex in 0..<channelCount {
                sum += Float(channels[channelIndex][frame]) / scale
            }
            mono[frame] = sum / Float(channelCount)
        }
        return mono
    }

    private static func resampleLinear(
        _ samples: [Float],
        sourceSampleRate: Double,
        targetSampleRate: Double
    ) -> [Float] {
        guard !samples.isEmpty else { return [] }
        guard sourceSampleRate > 0, targetSampleRate > 0 else { return samples }
        if abs(sourceSampleRate - targetSampleRate) < 0.001 { return samples }

        let targetFrameCount = max(1, Int(Double(samples.count) * targetSampleRate / sourceSampleRate))
        if targetFrameCount == 1 {
            return [samples[0]]
        }

        let ratio = sourceSampleRate / targetSampleRate
        var output = Array(repeating: Float.zero, count: targetFrameCount)
        for targetIndex in 0..<targetFrameCount {
            let sourcePosition = Double(targetIndex) * ratio
            let lowerIndex = Int(sourcePosition)
            let upperIndex = min(lowerIndex + 1, samples.count - 1)
            let fraction = Float(sourcePosition - Double(lowerIndex))

            let lower = samples[min(lowerIndex, samples.count - 1)]
            let upper = samples[upperIndex]
            output[targetIndex] = lower + ((upper - lower) * fraction)
        }
        return output
    }

    private static func encodePCM16(samples: [Float]) -> Data {
        var data = Data(count: samples.count * 2)
        data.withUnsafeMutableBytes { raw in
            guard let dst = raw.bindMemory(to: Int16.self).baseAddress else { return }
            for (index, sample) in samples.enumerated() {
                let clamped = max(-1.0, min(1.0, sample))
                dst[index] = Int16(clamped * Float(Int16.max))
            }
        }
        return data
    }
}

enum AudioVAD {
    static func isVoice(_ buffer: AVAudioPCMBuffer) -> Bool {
        guard buffer.format.commonFormat == .pcmFormatFloat32,
              let channel = buffer.floatChannelData?.pointee
        else { return true }

        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return false }

        var sumSquares: Float = 0
        for i in 0..<frames {
            let v = channel[i]
            sumSquares += v * v
        }
        let rms = sqrt(sumSquares / Float(frames))

        return rms > 0.012
    }
}
