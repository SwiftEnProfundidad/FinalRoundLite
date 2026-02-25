@preconcurrency import AVFoundation
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

    private var converter: AVAudioConverter?
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

        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        )!

        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        let stream = AsyncStream<AudioChunk> { cont in
            self.continuation = cont
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.handleIncomingBuffer(buffer, targetFormat: targetFormat)
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
        converter = nil
        pcm16Buffer.removeAll(keepingCapacity: true)
        voiceFrameCount = 0
        totalFrameCount = 0
        continuation?.finish()
        continuation = nil
    }

    private func handleIncomingBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        guard let converter else { return }

        let voice = AudioVAD.isVoice(buffer)
        totalFrameCount += Int(buffer.frameLength)
        if voice { voiceFrameCount += Int(buffer.frameLength) }

        guard let converted = convert(buffer, with: converter, to: targetFormat) else { return }
        appendPCM16(from: converted)

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

    private func convert(
        _ buffer: AVAudioPCMBuffer,
        with converter: AVAudioConverter,
        to targetFormat: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let ratio = targetSampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64
        guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return nil }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        converter.convert(to: out, error: &error, withInputFrom: inputBlock)
        if error != nil { return nil }
        return out
    }

    private func appendPCM16(from buffer: AVAudioPCMBuffer) {
        guard buffer.format.commonFormat == .pcmFormatFloat32,
              let channel = buffer.floatChannelData?.pointee
        else { return }

        let frames = Int(buffer.frameLength)
        var data = Data(count: frames * 2)
        data.withUnsafeMutableBytes { raw in
            guard let dst = raw.bindMemory(to: Int16.self).baseAddress else { return }
            for i in 0..<frames {
                let x = max(-1.0, min(1.0, channel[i]))
                dst[i] = Int16(x * Float(Int16.max))
            }
        }
        pcm16Buffer.append(data)
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
