import AVFoundation
import Foundation

@MainActor
final class TonePlayer: ObservableObject {
    @Published private(set) var error: String?
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            self.error = "Audio engine failed to start: \(error.localizedDescription)"
        }
    }

    func playNote(_ note: String) {
        playSequence([(note, [0])], arpeggio: false)
    }

    func playChord(root: String, quality: ChordQuality, arpeggio: Bool = false) {
        playSequence([(root, quality.intervals)], arpeggio: arpeggio)
    }

    func playProgression(_ chords: [ChordEntry], arpeggio: Bool) {
        playSequence(chords.map { ($0.root, $0.quality.intervals) }, arpeggio: arpeggio)
    }

    private func playSequence(_ chords: [(String, [Int])], arpeggio: Bool) {
        var buffers: [AVAudioPCMBuffer] = []
        for (root, intervals) in chords {
            guard let rootFrequency = frequency(for: root) else {
                error = "Cannot play the note \(root)."
                return
            }
            let frequencies = intervals.map { rootFrequency * pow(2.0, Double($0) / 12.0) }
            if arpeggio {
                buffers.append(contentsOf: frequencies.map { makeChordBuffer(frequencies: [$0], duration: 0.22) })
            } else {
                buffers.append(makeChordBuffer(frequencies: frequencies, duration: 0.5))
            }
        }
        do {
            if !engine.isRunning {
                try engine.start()
            }
            player.stop()
            for buffer in buffers {
                player.scheduleBuffer(buffer)
            }
            player.play()
            error = nil
        } catch {
            self.error = "Audio engine failed to start: \(error.localizedDescription)"
        }
    }

    private func makeChordBuffer(frequencies: [Double], duration: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else {
            return buffer
        }

        let voiceGain = 0.24 / max(1.0, Double(frequencies.count))

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let fade = min(1.0, Double(frame) / 500.0) * min(1.0, Double(Int(frameCount) - frame) / 500.0)
            let sample = frequencies.reduce(0.0) { partial, frequency in
                partial + sin(2.0 * Double.pi * frequency * t)
            } * voiceGain * fade
            channel[frame] = Float(sample)
        }

        return buffer
    }

    private func frequency(for note: String) -> Double? {
        guard let semitone = Note.pitchClass(note) else { return nil }

        let midi = 60 + semitone
        return 440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }
}
