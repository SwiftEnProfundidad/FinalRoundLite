import Foundation

enum WavEncoder {
    static func wrapPCM16LEAsWav(pcmData: Data, sampleRate: Int, channels: Int) -> Data {
        precondition(channels > 0)
        let bitsPerSample = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8

        var header = Data()
        header.append(contentsOf: "RIFF".utf8)
        header.append(uint32LE(36 + UInt32(pcmData.count)))
        header.append(contentsOf: "WAVE".utf8)

        header.append(contentsOf: "fmt ".utf8)
        header.append(uint32LE(16)) // PCM fmt chunk size
        header.append(uint16LE(1)) // PCM format
        header.append(uint16LE(UInt16(channels)))
        header.append(uint32LE(UInt32(sampleRate)))
        header.append(uint32LE(UInt32(byteRate)))
        header.append(uint16LE(UInt16(blockAlign)))
        header.append(uint16LE(UInt16(bitsPerSample)))

        header.append(contentsOf: "data".utf8)
        header.append(uint32LE(UInt32(pcmData.count)))

        var wav = Data()
        wav.append(header)
        wav.append(pcmData)
        return wav
    }

    private static func uint16LE(_ value: UInt16) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: MemoryLayout<UInt16>.size)
    }

    private static func uint32LE(_ value: UInt32) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: MemoryLayout<UInt32>.size)
    }
}

